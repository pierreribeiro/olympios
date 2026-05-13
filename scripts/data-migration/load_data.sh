#!/usr/bin/env bash
# =============================================================================
# Perseus Database Migration - Data Loading Script (Local PostgreSQL)
# =============================================================================
# Purpose: Load CSV data exported from SQL Server into a local PostgreSQL
#          instance (running outside Docker) using psql.
#
# Authentication: Uses ~/.pgpass (must be pre-configured with 0600 permissions)
#
# Usage:
#   ./load_data.sh [OPTIONS]
#
# Options:
#   --validate-only  Only run validation queries, skip data loading
#   --tier N         Load only specific tier (0-4), default: all tiers
#   --no-truncate    Skip TRUNCATE before each table load (append mode)
#   --help           Show this help message
#
# Configuration:
#   All settings are read from .env in the script directory.
#   See .env.example for available variables.
#
# Exit Codes:
#   0 - Success
#   1 - Error (configuration, prerequisites, execution)
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# GLOBAL CONSTANTS
# -----------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly ENV_FILE="${SCRIPT_DIR}/.env"

# Colors for output (disable if not a terminal)
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly CYAN=''
    readonly BOLD=''
    readonly NC=''
fi

# -----------------------------------------------------------------------------
# GLOBAL VARIABLES (populated by load_environment / parse_args)
# -----------------------------------------------------------------------------
PG_HOST=""
PG_PORT=""
PG_DATABASE=""
PG_USER=""
PG_SCHEMA=""
DATA_DIR=""
LOG_DIR=""
LOG_FILE=""

VALIDATE_ONLY=false
SPECIFIC_TIER=""
NO_TRUNCATE=false

# Statistics
STATS_START_TIME=""
STATS_TABLES_LOADED=0
STATS_TABLES_SKIPPED=0
STATS_TABLES_FAILED=0
STATS_TOTAL_ROWS=0

# Flag to track whether FK triggers were disabled (for cleanup trap)
FK_TRIGGERS_DISABLED=false

# -----------------------------------------------------------------------------
# LOGGING
# -----------------------------------------------------------------------------
log() {
    local level="$1"; shift
    local message="$*"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"

    # Append to log file (plain text)
    echo "[${ts}] [${level}] ${message}" >> "${LOG_FILE}"

    # Terminal output with colors
    case "${level}" in
        INFO)    echo -e "${CYAN}[INFO]${NC} ${message}" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} ${message}" ;;
        WARN)    echo -e "${YELLOW}[WARN]${NC} ${message}" ;;
        ERROR)   echo -e "${RED}[ERROR]${NC} ${message}" >&2 ;;
    esac
}

log_info()    { log INFO "$@"; }
log_success() { log SUCCESS "$@"; }
log_warn()    { log WARN "$@"; }
log_error()   { log ERROR "$@"; }

print_header() {
    local header="$1"
    local sep
    sep="$(printf '=%.0s' {1..60})"
    echo ""
    echo -e "${BOLD}${sep}${NC}"
    echo -e "${BOLD}${header}${NC}"
    echo -e "${BOLD}${sep}${NC}"
    echo ""
    log_info "${header}"
}

# -----------------------------------------------------------------------------
# USAGE
# -----------------------------------------------------------------------------
show_help() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Load CSV files (exported from SQL Server) into a local PostgreSQL instance.
Authentication is handled via ~/.pgpass (must be pre-configured).

Options:
  --validate-only   Only run referential integrity validation, skip loading
  --tier N          Load only specific tier (0-4); default: all tiers
  --no-truncate     Skip TRUNCATE before each table (append mode, not idempotent)
  --help            Show this help message

Configuration (.env):
  PG_HOST           PostgreSQL hostname       (default: localhost)
  PG_PORT           PostgreSQL port            (default: 5432)
  PG_DATABASE       Target database name       (default: perseus_dev)
  PG_USER           PostgreSQL user            (default: perseus_admin)
  PG_SCHEMA         Target schema              (default: perseus)
  DATA_DIR          CSV directory path         (default: /tmp/perseus-data-export)
  LOG_DIR           Log output directory       (default: ./logs)

Examples:
  ${SCRIPT_NAME}                   # Load all tiers
  ${SCRIPT_NAME} --tier 3          # Load tier 3 only
  ${SCRIPT_NAME} --validate-only   # Run validation only
  ${SCRIPT_NAME} --no-truncate     # Append mode (skip TRUNCATE)
EOF
    exit 0
}

# -----------------------------------------------------------------------------
# CONFIGURATION
# -----------------------------------------------------------------------------
load_environment() {
    if [[ -f "${ENV_FILE}" ]]; then
        set -a
        # shellcheck source=/dev/null
        source "${ENV_FILE}"
        set +a
    else
        log_warn ".env file not found at ${ENV_FILE}; using defaults only"
    fi

    # Apply defaults (env/file values take precedence)
    PG_HOST="${PG_HOST:-localhost}"
    PG_PORT="${PG_PORT:-5432}"
    PG_DATABASE="${PG_DATABASE:-perseus_dev}"
    PG_USER="${PG_USER:-perseus_admin}"
    PG_SCHEMA="${PG_SCHEMA:-perseus}"
    DATA_DIR="${DATA_DIR:-/tmp/perseus-data-export}"
    LOG_DIR="${LOG_DIR:-${SCRIPT_DIR}/.logs}"

    # Ensure log directory exists
    mkdir -p "${LOG_DIR}"
    LOG_FILE="${LOG_DIR}/load_data-${TIMESTAMP}.log"
    touch "${LOG_FILE}"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --validate-only)
                VALIDATE_ONLY=true
                shift
                ;;
            --tier)
                if [[ $# -lt 2 ]]; then
                    log_error "--tier requires a value (0-4)"
                    exit 1
                fi
                SPECIFIC_TIER="$2"
                if ! [[ "${SPECIFIC_TIER}" =~ ^[0-4]$ ]]; then
                    log_error "Invalid tier: ${SPECIFIC_TIER} (must be 0-4)"
                    exit 1
                fi
                shift 2
                ;;
            --no-truncate)
                NO_TRUNCATE=true
                shift
                ;;
            --help)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Run '${SCRIPT_NAME} --help' for usage."
                exit 1
                ;;
        esac
    done
}

# Build the base psql command array (used throughout the script)
build_psql_cmd() {
    PSQL_CMD=(
        psql
        -h "${PG_HOST}"
        -p "${PG_PORT}"
        -U "${PG_USER}"
        -d "${PG_DATABASE}"
        -v "ON_ERROR_STOP=1"
    )
}

# -----------------------------------------------------------------------------
# PRE-FLIGHT CHECKS
# -----------------------------------------------------------------------------
preflight_checks() {
    print_header "Pre-flight Checks"

    # 1. psql available
    if ! command -v psql &>/dev/null; then
        log_error "psql is not installed or not in PATH"
        exit 1
    fi
    log_success "psql found: $(psql --version | head -1)"

    # 2. Data directory exists
    if [[ ! -d "${DATA_DIR}" ]]; then
        log_error "Data directory not found: ${DATA_DIR}"
        exit 1
    fi
    local csv_count
    csv_count=$(find "${DATA_DIR}" -maxdepth 1 -name '##perseus_tier_*.csv' -type f | wc -l | tr -d ' ')
    if [[ "${csv_count}" -eq 0 ]]; then
        log_error "No CSV files matching ##perseus_tier_*.csv found in ${DATA_DIR}"
        exit 1
    fi
    log_success "Data directory OK: ${csv_count} CSV file(s) found"

    # 3. Database connectivity (relies on .pgpass)
    if ! "${PSQL_CMD[@]}" -c "SELECT 1;" &>/dev/null; then
        log_error "Cannot connect to PostgreSQL (${PG_HOST}:${PG_PORT}/${PG_DATABASE} as ${PG_USER})"
        log_error "Verify that ~/.pgpass is configured and has 0600 permissions"
        exit 1
    fi
    log_success "Database connectivity OK (${PG_HOST}:${PG_PORT}/${PG_DATABASE})"

    # 4. Target schema exists
    local schema_exists
    schema_exists=$("${PSQL_CMD[@]}" -tAc \
        "SELECT 1 FROM information_schema.schemata WHERE schema_name = '${PG_SCHEMA}';" 2>/dev/null || true)
    if [[ "${schema_exists}" != "1" ]]; then
        log_error "Schema '${PG_SCHEMA}' does not exist in database '${PG_DATABASE}'"
        exit 1
    fi
    log_success "Schema '${PG_SCHEMA}' exists"

    echo ""
}

# -----------------------------------------------------------------------------
# FK TRIGGER MANAGEMENT
# -----------------------------------------------------------------------------
# Uses session_replication_role which is more efficient for a single direct
# psql session (no Docker exec boundary issues). Falls back to per-table
# ALTER TABLE if the role lacks SUPERUSER privileges.
# -----------------------------------------------------------------------------
disable_fk_triggers() {
    log_info "Disabling FK triggers (session_replication_role = replica)..."

    if "${PSQL_CMD[@]}" -c "SET session_replication_role = 'replica';" &>/dev/null; then
        FK_TRIGGERS_DISABLED=true
        log_success "FK triggers disabled via session_replication_role"
        return 0
    fi

    # Fallback: per-table ALTER TABLE (works without SUPERUSER)
    log_warn "session_replication_role not available; falling back to per-table ALTER TABLE"
    "${PSQL_CMD[@]}" <<-SQLDISABLE
DO \$\$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = '${PG_SCHEMA}'
    LOOP
        EXECUTE format('ALTER TABLE ${PG_SCHEMA}.%I DISABLE TRIGGER ALL', r.tablename);
    END LOOP;
END \$\$;
SQLDISABLE
    FK_TRIGGERS_DISABLED=true
    log_success "FK triggers disabled via ALTER TABLE"
}

enable_fk_triggers() {
    if [[ "${FK_TRIGGERS_DISABLED}" != "true" ]]; then
        return 0
    fi

    log_info "Re-enabling FK triggers..."

    # Try session_replication_role first
    if "${PSQL_CMD[@]}" -c "SET session_replication_role = 'origin';" &>/dev/null; then
        FK_TRIGGERS_DISABLED=false
        log_success "FK triggers re-enabled via session_replication_role"
        return 0
    fi

    # Fallback: per-table ALTER TABLE
    "${PSQL_CMD[@]}" <<-SQLENABLE
DO \$\$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = '${PG_SCHEMA}'
    LOOP
        EXECUTE format('ALTER TABLE ${PG_SCHEMA}.%I ENABLE TRIGGER ALL', r.tablename);
    END LOOP;
END \$\$;
SQLENABLE
    FK_TRIGGERS_DISABLED=false
    log_success "FK triggers re-enabled via ALTER TABLE"
}

# -----------------------------------------------------------------------------
# CLEANUP TRAP
# -----------------------------------------------------------------------------
cleanup() {
    local exit_code=$?
    if [[ "${FK_TRIGGERS_DISABLED}" == "true" ]]; then
        log_warn "Script exiting with FK triggers still disabled — re-enabling..."
        enable_fk_triggers || log_error "CRITICAL: Failed to re-enable FK triggers! Manual intervention required."
    fi
    exit "${exit_code}"
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# TABLE DEFINITIONS (dependency-ordered tiers)
# -----------------------------------------------------------------------------
TIER0_TABLES=(
    "permissions"    
    "scraper"
    "unit"
    "recipe_category"
    "recipe_type"
    "run_type"
    "transition_type"
    "workflow_type"
    "poll"
    "cm_unit_dimensions"
    "cm_user"
    "cm_user_group"
    "coa"
    "coa_spec"
    "color"
    "container"
    "container_type"
    "goo_type"
    "manufacturer"
    "display_layout"
    "display_type"
    "m_downstream"
    "external_goo_type"
    "m_upstream"
    "m_upstream_dirty_leaves"
    "goo_type_property_def"
    "field_map"
    "goo_qc"
    "smurf_robot"
    "smurf_robot_part"
    "property_type"
)

TIER1_TABLES=(
    "property"
    "robot_log_type"
    "container_type_position"
    "goo_type_combine_target"
    "container_history"
    "workflow"
    "perseus_user"
    "field_map_display_type"
    "field_map_display_type_user"
)

TIER2_TABLES=(
    "feed_type"
    "goo_type_combine_component"
    "material_inventory_threshold"
    "material_inventory_threshold_notify_user"
    "workflow_section"
    "workflow_attachment"
    "workflow_step"
    "recipe"
    "smurf_group"
    "smurf_goo_type"
    "property_option"
)

TIER3_TABLES=(
    "goo"
    "fatsmurf"
    "goo_attachment"
    "goo_comment"
    "goo_history"
    "fatsmurf_attachment"
    "fatsmurf_comment"
    "fatsmurf_history"
    "recipe_part"
    "smurf"
    "submission"
    "material_qc"
)

TIER4_TABLES=(
    "material_transition"
    "transition_material"
    "material_inventory"
    "fatsmurf_reading"
    "poll_history"
    "submission_entry"
    "robot_log"
    "robot_log_read"
    "robot_log_transfer"
    "robot_log_error"
    "robot_log_container_sequence"
)

# -----------------------------------------------------------------------------
# DATA LOADING FUNCTIONS
# -----------------------------------------------------------------------------

# Load a single table from its CSV file.
# Args: $1=tier_number  $2=table_name
load_table() {
    local tier_number="$1"
    local table_name="$2"
    local csv_file="${DATA_DIR}/##perseus_tier_${tier_number}_${table_name}.csv"

    # Missing CSV — not extracted yet, skip with warning
    if [[ ! -f "${csv_file}" ]]; then
        log_warn "CSV not found for '${table_name}' (skipping)"
        STATS_TABLES_SKIPPED=$((STATS_TABLES_SKIPPED + 1))
        return 0
    fi

    # Empty CSV — 0 bytes, nothing to load
    if [[ ! -s "${csv_file}" ]]; then
        log_warn "CSV is empty for '${table_name}' (0 bytes, skipping)"
        STATS_TABLES_SKIPPED=$((STATS_TABLES_SKIPPED + 1))
        return 0
    fi

    log_info "Loading: ${PG_SCHEMA}.${table_name}"

    # Truncate before load for idempotency (unless --no-truncate)
    if [[ "${NO_TRUNCATE}" != "true" ]]; then
        "${PSQL_CMD[@]}" -c "TRUNCATE ${PG_SCHEMA}.${table_name} CASCADE;" >> "${LOG_FILE}" 2>&1 || true
    fi

    # Load CSV using \copy (client-side COPY — no SUPERUSER required, reads local file)
    if "${PSQL_CMD[@]}" \
        -c "\copy ${PG_SCHEMA}.${table_name} FROM '${csv_file}' WITH (FORMAT CSV, HEADER false, DELIMITER ',')" \
        >> "${LOG_FILE}" 2>&1; then

        # Get and log row count
        local row_count
        row_count=$("${PSQL_CMD[@]}" -tAc "SELECT COUNT(*) FROM ${PG_SCHEMA}.${table_name};" 2>/dev/null)
        row_count="${row_count// /}"

        log_success "  ✓ ${table_name}: ${row_count} rows"
        STATS_TABLES_LOADED=$((STATS_TABLES_LOADED + 1))
        STATS_TOTAL_ROWS=$((STATS_TOTAL_ROWS + row_count))
        return 0
    else
        log_error "  ✗ Failed to load ${table_name}"
        STATS_TABLES_FAILED=$((STATS_TABLES_FAILED + 1))
        return 1
    fi
}

# Load all tables for a given tier.
# Args: $1=tier_number  $2..=table_names
load_tier() {
    local tier_number="$1"; shift
    local tables=("$@")

    print_header "TIER ${tier_number}: Loading ${#tables[@]} tables"

    local tier_loaded=0
    local tier_failed=0

    for table in "${tables[@]}"; do
        if load_table "${tier_number}" "${table}"; then
            tier_loaded=$((tier_loaded + 1))
        else
            tier_failed=$((tier_failed + 1))
        fi
    done

    log_info "Tier ${tier_number} complete: ${tier_loaded} loaded, ${tier_failed} failed"
}

# -----------------------------------------------------------------------------
# VALIDATION
# -----------------------------------------------------------------------------
run_validation() {
    print_header "Post-Load Validation"

    # Run referential integrity check if the SQL file exists
    local ri_script="${SCRIPT_DIR}/validate-referential-integrity.sql"
    if [[ -f "${ri_script}" ]]; then
        log_info "Running referential integrity validation..."
        "${PSQL_CMD[@]}" -f "${ri_script}" 2>&1 | tee -a "${LOG_FILE}"
    else
        log_warn "validate-referential-integrity.sql not found, skipping"
    fi

    # Summary stats
    "${PSQL_CMD[@]}" <<-EOSQL
SELECT 'Tables Loaded: ' || COUNT(DISTINCT table_name)::TEXT
FROM information_schema.tables
WHERE table_schema = '${PG_SCHEMA}';

SELECT 'Total Rows: ' || TO_CHAR(SUM(n_tup_ins), 'FM999,999,999')
FROM pg_stat_user_tables
WHERE schemaname = '${PG_SCHEMA}';

SELECT 'Foreign Keys: ' || COUNT(*)::TEXT
FROM information_schema.table_constraints
WHERE constraint_schema = '${PG_SCHEMA}' AND constraint_type = 'FOREIGN KEY';
EOSQL
}

# -----------------------------------------------------------------------------
# SUMMARY
# -----------------------------------------------------------------------------
print_summary() {
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - STATS_START_TIME))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    print_header "Load Summary"
    log_info "Tables loaded:  ${STATS_TABLES_LOADED}"
    log_info "Tables skipped: ${STATS_TABLES_SKIPPED}"
    log_info "Tables failed:  ${STATS_TABLES_FAILED}"
    log_info "Total rows:     ${STATS_TOTAL_ROWS}"
    log_info "Duration:       ${minutes}m ${seconds}s"
    log_info "Log file:       ${LOG_FILE}"
    echo ""

    if [[ "${STATS_TABLES_FAILED}" -gt 0 ]]; then
        log_warn "Some tables failed to load — check the log for details."
    fi

    log_info "Next steps:"
    log_info "  1. Validate integrity: ${SCRIPT_NAME} --validate-only"
    log_info "  2. Check row counts:   psql -f validate-row-counts.sql"
    log_info "  3. Run checksums:      psql -f validate-checksums.sql"
}

# -----------------------------------------------------------------------------
# MAIN
# -----------------------------------------------------------------------------
main() {
    # Fast-path: handle --help before any env loading (avoids LOG_FILE issues)
    for arg in "$@"; do
        if [[ "${arg}" == "--help" ]]; then
            show_help
        fi
    done

    # Order matters: load env first, parse args (overrides), then build psql cmd
    load_environment
    parse_args "$@"
    build_psql_cmd

    # Initialize log
    echo "=== Perseus Data Load - ${TIMESTAMP} ===" > "${LOG_FILE}"

    print_header "Perseus Data Migration — Local PostgreSQL Loader"
    log_info "Target:    ${PG_HOST}:${PG_PORT}/${PG_DATABASE} (schema: ${PG_SCHEMA})"
    log_info "User:      ${PG_USER} (auth via .pgpass)"
    log_info "Data dir:  ${DATA_DIR}"

    # Pre-flight
    preflight_checks

    # Validate-only mode
    if [[ "${VALIDATE_ONLY}" == "true" ]]; then
        log_info "Validate-only mode: skipping data load"
        run_validation
        exit 0
    fi

    # Record start time
    STATS_START_TIME=$(date +%s)

    # Disable FK triggers before loading
    disable_fk_triggers

    # Load tiers
    if [[ -z "${SPECIFIC_TIER}" ]]; then
        load_tier 0 "${TIER0_TABLES[@]}"
        load_tier 1 "${TIER1_TABLES[@]}"
        load_tier 2 "${TIER2_TABLES[@]}"
        load_tier 3 "${TIER3_TABLES[@]}"
        load_tier 4 "${TIER4_TABLES[@]}"
    else
        case "${SPECIFIC_TIER}" in
            0) load_tier 0 "${TIER0_TABLES[@]}" ;;
            1) load_tier 1 "${TIER1_TABLES[@]}" ;;
            2) load_tier 2 "${TIER2_TABLES[@]}" ;;
            3) load_tier 3 "${TIER3_TABLES[@]}" ;;
            4) load_tier 4 "${TIER4_TABLES[@]}" ;;
        esac
    fi

    # Re-enable FK triggers
    enable_fk_triggers

    # Validation + summary
    run_validation
    print_summary

    if [[ "${STATS_TABLES_FAILED}" -gt 0 ]]; then
        exit 1
    fi

    log_success "Data load complete!"
    exit 0
}

main "$@"
