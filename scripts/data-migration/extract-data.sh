#!/usr/bin/env bash
# =============================================================================
# extract-data.sh - Production-grade SQL Server data extraction orchestrator
# =============================================================================
# Description: Orchestrates tiered data extraction from SQL Server with
#              comprehensive error handling, progress tracking, and validation.
#              Uses single-session execution (Option A) to preserve global temp
#              tables across all tiers when executing full range (0-4).
#
# Author: Perseus Migration Team
# Version: 1.0.0
# Date: 2026-01-29
#
# Usage: ./extract-data.sh [OPTIONS]
#   --dry-run           Validate setup without executing extraction
#   --tier N            Execute specific tier (0-4)
#   --tier START-END    Execute tier range (e.g., 0-2)
#   --no-cleanup        Skip temp table cleanup on exit
#   --timeout SECONDS   Query timeout in seconds (default: 1800)
#   --help              Display this help message
#
# Configuration Precedence:
#   1. CLI Flags        Highest priority (--timeout, --tier, etc.)
#   2. .env File        Primary configuration source (REQUIRED)
#   3. Script Defaults  Fallback if not in .env
#
#   NOTE: Environment variables are IGNORED (security best practice)
#
# .env Configuration (see .env.example):
#   SQL_SERVER          SQL Server hostname/IP (REQUIRED)
#   SQL_DATABASE        Database name (REQUIRED)
#   SQL_USER            SQL Server username (REQUIRED)
#   SQL_PASSWORD        SQL Server password (REQUIRED)
#   SQL_TIMEOUT         Query timeout in seconds (default: 3600)
#                       → Mapped to TIMEOUT variable in script
#   DATA_DIR            CSV output directory (default: /tmp/perseus-data-export)
#   LOG_DIR             Log output directory (default: ./logs)
#
# CLI Flags (Override .env):
#   --timeout SECONDS   Override SQL_TIMEOUT from .env
#   --tier N|START-END  Execute specific tier(s)
#   --dry-run           Validate without executing
#   --no-cleanup        Skip temp table cleanup
#
# Exit Codes:
#   0 - Success
#   1 - Error (configuration, prerequisites, execution)
#   2 - User interrupt (Ctrl+C)
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# GLOBAL CONSTANTS
# -----------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly ENV_FILE="${SCRIPT_DIR}/.env"

# Default configuration
readonly DEFAULT_DATA_DIR="/tmp/perseus-data-export"
readonly DEFAULT_LOG_DIR="${SCRIPT_DIR}/logs"
readonly DEFAULT_TIMEOUT=3600
readonly MIN_DISK_SPACE_GB=3
readonly MIN_TEMPDB_SPACE_GB=5

# Colors for output (disable if not a terminal)
if [[ -t 1 ]]; then
    readonly COLOR_RESET='\033[0m'
    readonly COLOR_RED='\033[0;31m'
    readonly COLOR_GREEN='\033[0;32m'
    readonly COLOR_YELLOW='\033[0;33m'
    readonly COLOR_BLUE='\033[0;34m'
    readonly COLOR_CYAN='\033[0;36m'
    readonly COLOR_BOLD='\033[1m'
else
    readonly COLOR_RESET=''
    readonly COLOR_RED=''
    readonly COLOR_GREEN=''
    readonly COLOR_YELLOW=''
    readonly COLOR_BLUE=''
    readonly COLOR_CYAN=''
    readonly COLOR_BOLD=''
fi

# -----------------------------------------------------------------------------
# GLOBAL VARIABLES
# -----------------------------------------------------------------------------
# IMPORTANT: Variables initialized EMPTY to enforce .env-first precedence.
# - .env values loaded in load_environment() (mandatory preference)
# - Defaults applied ONLY if .env doesn't define variable
# - Environment variables IGNORED (security best practice)
# - CLI flags override .env (parsed after load_environment)
# -----------------------------------------------------------------------------
DATA_DIR=""
LOG_DIR=""
TIMEOUT=""

# LOG_FILE initialized early with default, then updated in load_environment() if needed
LOG_FILE="${DEFAULT_LOG_DIR}/extract-data-${TIMESTAMP}.log"
DRY_RUN=0
TIER_START=-1
TIER_END=-1
DO_CLEANUP=1
SESSION_ID=""
TEMP_TABLES=()

# Connection parameters (loaded from .env)
SQL_SERVER=""
SQL_DATABASE=""
SQL_USER=""
SQL_PASSWORD=""

# Statistics tracking
STATS_START_TIME=""
STATS_TABLES_PROCESSED=0
STATS_TOTAL_ROWS=0
STATS_TOTAL_CSV_SIZE=0

# -----------------------------------------------------------------------------
# LOGGING FUNCTIONS
# -----------------------------------------------------------------------------

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    # Write to log file
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"

    # Write to stdout with colors
    case "${level}" in
        INFO)
            echo -e "${COLOR_CYAN}[INFO]${COLOR_RESET} ${message}"
            ;;
        SUCCESS)
            echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} ${message}"
            ;;
        WARN)
            echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} ${message}"
            ;;
        ERROR)
            echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} ${message}" >&2
            ;;
        DEBUG)
            echo -e "${COLOR_BLUE}[DEBUG]${COLOR_RESET} ${message}"
            ;;
    esac
}

log_info() { log INFO "$@"; }
log_success() { log SUCCESS "$@"; }
log_warn() { log WARN "$@"; }
log_error() { log ERROR "$@"; }
log_debug() { log DEBUG "$@"; }

print_header() {
    local header="$1"
    local separator
    separator="$(printf '=%.0s' {1..80})"

    echo ""
    echo -e "${COLOR_BOLD}${separator}${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${header}${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${separator}${COLOR_RESET}"
    echo ""

    log INFO "${header}"
}

print_section() {
    local section="$1"
    local separator
    separator="$(printf -- '-%.0s' {1..80})"

    echo ""
    echo -e "${COLOR_BOLD}${section}${COLOR_RESET}"
    echo -e "${separator}"

    log INFO "${section}"
}

# -----------------------------------------------------------------------------
# ERROR HANDLING & CLEANUP
# -----------------------------------------------------------------------------

cleanup() {
    local exit_code=$?

    log_info "Cleanup initiated (exit code: ${exit_code})"

    # Clean up temporary combined scripts
    if [[ -n "${SCRIPT_DIR}" && -n "${TIMESTAMP}" ]]; then
        local tmp_script="${SCRIPT_DIR}/.tmp-combined-tiers-${TIMESTAMP}.sql"
        if [[ -f "${tmp_script}" ]]; then
            log_debug "Removing temporary combined script: ${tmp_script}"
            rm -f "${tmp_script}" 2>> "${LOG_FILE}" || log_warn "Could not remove: ${tmp_script}"
        fi
    fi

    if [[ ${DO_CLEANUP} -eq 1 && ${#TEMP_TABLES[@]} -gt 0 ]]; then
        log_info "Dropping temporary tables..."

        for table in "${TEMP_TABLES[@]}"; do
            if [[ -n "${table}" ]]; then
                log_debug "Dropping table: ${table}"
                sqlcmd -S "${SQL_SERVER}" -U "${SQL_USER}" -P "${SQL_PASSWORD}" \
                    -d "${SQL_DATABASE}" -b -t "${TIMEOUT}" \
                    -Q "IF OBJECT_ID('tempdb..${table}') IS NOT NULL DROP TABLE ${table};" \
                    >> "${LOG_FILE}" 2>&1 || log_warn "Failed to drop table: ${table}"
            fi
        done

        log_success "Temporary tables cleanup completed"
    fi

    if [[ ${exit_code} -eq 0 ]]; then
        log_success "Script completed successfully"
    elif [[ ${exit_code} -eq 2 ]]; then
        log_warn "Script interrupted by user"
    else
        log_error "Script failed with exit code: ${exit_code}"
    fi

    return ${exit_code}
}

handle_interrupt() {
    log_warn "Received interrupt signal (Ctrl+C)"
    log_info "Initiating graceful shutdown..."
    exit 2
}

error_exit() {
    local message="$1"
    local exit_code="${2:-1}"

    log_error "${message}"
    log_error "Exiting with code ${exit_code}"
    exit "${exit_code}"
}

# Register signal handlers
trap cleanup EXIT
trap handle_interrupt INT TERM

# -----------------------------------------------------------------------------
# HELP & USAGE
# -----------------------------------------------------------------------------

show_help() {
    cat << EOF
${COLOR_BOLD}USAGE:${COLOR_RESET}
    ${SCRIPT_NAME} [OPTIONS]

${COLOR_BOLD}DESCRIPTION:${COLOR_RESET}
    Production-grade SQL Server data extraction orchestrator for Perseus migration.
    Extracts data in dependency-ordered tiers (0-4), validates output, and provides
    comprehensive error handling and progress tracking.

    EXECUTION STRATEGY:
    - Full tier range (0-4): Combined single-session execution (Option A)
      Preserves global temp tables (##) across all tiers
    - Partial/single tier: Individual tier execution
      NOTE: Global temp tables may not persist between separate executions

${COLOR_BOLD}OPTIONS:${COLOR_RESET}
    --dry-run              Validate setup without executing extraction
    --tier N               Execute specific tier (0-4)
    --tier START-END       Execute tier range (e.g., 0-2)
    --no-cleanup           Skip temp table cleanup on exit
    --timeout SECONDS      Query timeout in seconds (default: ${DEFAULT_TIMEOUT})
    --help                 Display this help message

${COLOR_BOLD}CONFIGURATION PRECEDENCE:${COLOR_RESET}
    1. CLI flags           Highest priority (override .env values)
    2. .env file           Primary configuration source (REQUIRED)
    3. Script defaults     Fallback if not defined in .env

    ⚠️  Environment variables are IGNORED (security best practice)

${COLOR_BOLD}.ENV CONFIGURATION:${COLOR_RESET}
    Required:
      SQL_SERVER           SQL Server hostname/IP
      SQL_DATABASE         Database name
      SQL_USER             SQL Server username
      SQL_PASSWORD         SQL Server password

    Optional (with defaults):
      SQL_TIMEOUT          Query timeout (default: ${DEFAULT_TIMEOUT}s)
      DATA_DIR             CSV directory (default: ${DEFAULT_DATA_DIR})
      LOG_DIR              Log directory (default: ${DEFAULT_LOG_DIR})

${COLOR_BOLD}CLI FLAGS (Override .env):${COLOR_RESET}
    --timeout SECONDS      Override SQL_TIMEOUT from .env

${COLOR_BOLD}REQUIRED FILES:${COLOR_RESET}
    .env                   Database connection configuration
    extract-tier-*.sql     Tier extraction scripts (0-4)

${COLOR_BOLD}EXAMPLES:${COLOR_RESET}
    # Extract all tiers with defaults
    ${SCRIPT_NAME}

    # Dry run to validate setup
    ${SCRIPT_NAME} --dry-run

    # Extract specific tier
    ${SCRIPT_NAME} --tier 2

    # Extract tier range
    ${SCRIPT_NAME} --tier 0-2

    # Custom timeout and no cleanup
    ${SCRIPT_NAME} --timeout 3600 --no-cleanup

${COLOR_BOLD}EXIT CODES:${COLOR_RESET}
    0  Success
    1  Error (configuration, prerequisites, execution)
    2  User interrupt (Ctrl+C)

${COLOR_BOLD}OUTPUT:${COLOR_RESET}
    Logs:  ${LOG_DIR}/extract-data-TIMESTAMP.log
    CSVs:  ${DATA_DIR}/*.csv

For more information, see: ${SCRIPT_DIR}/README.md
EOF
}

# -----------------------------------------------------------------------------
# ARGUMENT PARSING
# -----------------------------------------------------------------------------

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --dry-run)
                DRY_RUN=1
                log_info "Dry-run mode enabled"
                shift
                ;;
            --tier)
                if [[ -z "${2:-}" ]]; then
                    error_exit "Option --tier requires an argument (N or START-END)"
                fi

                if [[ "$2" =~ ^([0-4])-([0-4])$ ]]; then
                    TIER_START="${BASH_REMATCH[1]}"
                    TIER_END="${BASH_REMATCH[2]}"

                    if [[ ${TIER_START} -gt ${TIER_END} ]]; then
                        error_exit "Invalid tier range: start (${TIER_START}) > end (${TIER_END})"
                    fi
                elif [[ "$2" =~ ^[0-4]$ ]]; then
                    TIER_START="$2"
                    TIER_END="$2"
                else
                    error_exit "Invalid tier argument: $2 (must be 0-4 or START-END)"
                fi

                log_info "Tier execution range: ${TIER_START}-${TIER_END}"
                shift 2
                ;;
            --no-cleanup)
                DO_CLEANUP=0
                log_info "Temp table cleanup disabled"
                shift
                ;;
            --timeout)
                if [[ -z "${2:-}" || ! "$2" =~ ^[0-9]+$ ]]; then
                    error_exit "Option --timeout requires a numeric argument (seconds)"
                fi
                TIMEOUT="$2"
                log_info "Query timeout set to ${TIMEOUT}s"
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1 (use --help for usage)"
                ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# CONFIGURATION LOADING
# -----------------------------------------------------------------------------

load_environment() {
    print_section "Loading Configuration"

    if [[ ! -f "${ENV_FILE}" ]]; then
        error_exit "Environment file not found: ${ENV_FILE}"
    fi

    log_info "Loading environment from: ${ENV_FILE}"

    # -------------------------------------------------------------------------
    # CONFIGURATION PRECEDENCE:
    # 1. .env values (HIGHEST priority - loaded here)
    # 2. Script defaults (applied if .env doesn't define variable)
    # 3. CLI flags (OVERRIDE .env in parse_arguments - called after this)
    #
    # NOTE: Environment variables are IGNORED (security best practice)
    # -------------------------------------------------------------------------

    local loaded_from_env=()

    # Parse .env file
    while IFS='=' read -r key value; do
        [[ "${key}" =~ ^#.*$ || -z "${key}" ]] && continue

        # Remove surrounding quotes
        value="${value#\"}"
        value="${value%\"}"
        value="${value#\'}"
        value="${value%\'}"

        # Load variables (.env-first, unconditional assignment)
        case "${key}" in
            SQL_SERVER)
                SQL_SERVER="${value}"
                loaded_from_env+=("SQL_SERVER")
                ;;
            SQL_DATABASE)
                SQL_DATABASE="${value}"
                loaded_from_env+=("SQL_DATABASE")
                ;;
            SQL_USER)
                SQL_USER="${value}"
                loaded_from_env+=("SQL_USER")
                ;;
            SQL_PASSWORD)
                SQL_PASSWORD="${value}"
                loaded_from_env+=("SQL_PASSWORD")
                ;;
            SQL_TIMEOUT)
                # Map: SQL_TIMEOUT (.env) → TIMEOUT (script variable)
                # Naming: .env uses SQL_TIMEOUT for clarity in config file
                #         Script uses TIMEOUT for brevity (passed to sqlcmd -t)
                TIMEOUT="${value}"
                loaded_from_env+=("SQL_TIMEOUT")
                ;;
            DATA_DIR)
                DATA_DIR="${value}"
                loaded_from_env+=("DATA_DIR")
                ;;
            LOG_DIR)
                LOG_DIR="${value}"
                loaded_from_env+=("LOG_DIR")
                ;;
            BCP_BATCH_SIZE|BCP_ERROR_FILE)
                export "${key}=${value}"
                loaded_from_env+=("${key}")
                ;;
        esac
    done < <(grep -E '^[A-Z_]+=' "${ENV_FILE}")

    # -------------------------------------------------------------------------
    # Apply defaults for variables NOT defined in .env
    # -------------------------------------------------------------------------
    if [[ -z "${DATA_DIR}" ]]; then
        DATA_DIR="${DEFAULT_DATA_DIR}"
        log_debug "DATA_DIR not in .env, using default: ${DEFAULT_DATA_DIR}"
    fi

    if [[ -z "${LOG_DIR}" ]]; then
        LOG_DIR="${DEFAULT_LOG_DIR}"
        log_debug "LOG_DIR not in .env, using default: ${DEFAULT_LOG_DIR}"
    fi

    if [[ -z "${TIMEOUT}" ]]; then
        TIMEOUT="${DEFAULT_TIMEOUT}"
        log_debug "SQL_TIMEOUT not in .env, using default: ${DEFAULT_TIMEOUT}s"
    fi

    # -------------------------------------------------------------------------
    # Validate required connection parameters
    # -------------------------------------------------------------------------
    local missing_params=()
    [[ -z "${SQL_SERVER}" ]] && missing_params+=("SQL_SERVER")
    [[ -z "${SQL_DATABASE}" ]] && missing_params+=("SQL_DATABASE")
    [[ -z "${SQL_USER}" ]] && missing_params+=("SQL_USER")
    [[ -z "${SQL_PASSWORD}" ]] && missing_params+=("SQL_PASSWORD")

    if [[ ${#missing_params[@]} -gt 0 ]]; then
        error_exit "Missing required connection parameters in .env: ${missing_params[*]}"
    fi

    # -------------------------------------------------------------------------
    # Initialize LOG_FILE path (now that LOG_DIR is finalized)
    # -------------------------------------------------------------------------
    LOG_FILE="${LOG_DIR}/extract-data-${TIMESTAMP}.log"

    # -------------------------------------------------------------------------
    # Configuration Summary
    # -------------------------------------------------------------------------
    log_success "Configuration loaded successfully"
    log_info "  Variables from .env: ${#loaded_from_env[@]} (${loaded_from_env[*]})"
    log_info "  Server:   ${SQL_SERVER}"
    log_info "  Database: ${SQL_DATABASE}"
    log_info "  User:     ${SQL_USER}"
    log_info "  Password: $(printf '*%.0s' {1..8})"
    log_info "  Timeout:  ${TIMEOUT}s"
    log_info "  Data Dir: ${DATA_DIR}"
    log_info "  Log Dir:  ${LOG_DIR}"
}

# -----------------------------------------------------------------------------
# PREREQUISITE CHECKS
# -----------------------------------------------------------------------------

check_prerequisites() {
    print_section "Prerequisite Checks"

    # Check sqlcmd availability
    if ! command -v sqlcmd &> /dev/null; then
        error_exit "sqlcmd not found in PATH. Install SQL Server command-line tools."
    fi
    log_success "sqlcmd found: $(command -v sqlcmd)"

    # Check bcp availability
    if ! command -v bcp &> /dev/null; then
        error_exit "bcp not found in PATH. Install SQL Server command-line tools."
    fi
    log_success "bcp found: $(command -v bcp)"

    # Create log directory
    if [[ ! -d "${LOG_DIR}" ]]; then
        mkdir -p "${LOG_DIR}" || error_exit "Failed to create log directory: ${LOG_DIR}"
        log_info "Created log directory: ${LOG_DIR}"
    fi

    # Initialize log file
    touch "${LOG_FILE}" || error_exit "Failed to create log file: ${LOG_FILE}"
    log_success "Log file initialized: ${LOG_FILE}"

    # Create data directory
    if [[ ! -d "${DATA_DIR}" ]]; then
        mkdir -p "${DATA_DIR}" || error_exit "Failed to create data directory: ${DATA_DIR}"
        log_info "Created data directory: ${DATA_DIR}"
    fi
    log_success "Data directory ready: ${DATA_DIR}"

    # Check local disk space
    log_info "Checking local disk space..."
    local available_gb
    available_gb=$(df -k "${DATA_DIR}" | awk 'NR==2 {printf "%.2f", $4/1024/1024}')

    log_info "  Available space: ${available_gb} GB"
    log_info "  Required space:  ${MIN_DISK_SPACE_GB} GB"

    if (( $(echo "${available_gb} < ${MIN_DISK_SPACE_GB}" | bc -l) )); then
        error_exit "Insufficient disk space: ${available_gb} GB < ${MIN_DISK_SPACE_GB} GB required"
    fi
    log_success "Sufficient disk space available"

    # Test database connectivity
    log_info "Testing database connectivity..."
    if ! sqlcmd -S "${SQL_SERVER}" -U "${SQL_USER}" -P "${SQL_PASSWORD}" \
        -d "${SQL_DATABASE}" -Q "SELECT 1 AS test;" -b > /dev/null 2>> "${LOG_FILE}"; then
        error_exit "Database connectivity test failed. Check credentials and network."
    fi
    log_success "Database connectivity verified"

    # Get session ID
    SESSION_ID=$(sqlcmd -S "${SQL_SERVER}" -U "${SQL_USER}" -P "${SQL_PASSWORD}" \
        -d "${SQL_DATABASE}" -h -1 -W -b -m 1 \
        -Q "SET NOCOUNT ON; SELECT @@SPID AS session_id;" 2>> "${LOG_FILE}" | grep -E '^[0-9]+$' | head -1)

    if [[ -n "${SESSION_ID}" && "${SESSION_ID}" =~ ^[0-9]+$ ]]; then
        log_success "Database session established (SPID: ${SESSION_ID})"
        log_info "  To kill if needed: KILL ${SESSION_ID};"
    else
        log_warn "Could not retrieve session ID"
    fi

    # Check tempdb space
    log_info "Checking tempdb free space..."
    local tempdb_free_gb
    tempdb_free_gb=$(sqlcmd -S "${SQL_SERVER}" -U "${SQL_USER}" -P "${SQL_PASSWORD}" \
        -d tempdb -h -1 -W -b -m 1 \
        -Q "SET NOCOUNT ON; SELECT CAST(SUM(unallocated_extent_page_count) * 8.0 / 1024 / 1024 AS DECIMAL(10,2)) AS free_gb FROM sys.dm_db_file_space_usage;" \
        2>> "${LOG_FILE}" | grep -E '^[0-9.]+$' | head -1)

    if [[ -n "${tempdb_free_gb}" && "${tempdb_free_gb}" =~ ^[0-9.]+$ ]]; then
        log_info "  tempdb free: ${tempdb_free_gb} GB"

        if (( $(echo "${tempdb_free_gb} < ${MIN_TEMPDB_SPACE_GB}" | bc -l) )); then
            log_warn "tempdb free space (${tempdb_free_gb} GB) below recommended minimum (${MIN_TEMPDB_SPACE_GB} GB)"
        else
            log_success "tempdb free space sufficient (${tempdb_free_gb} GB >= ${MIN_TEMPDB_SPACE_GB} GB)"
        fi
    else
        log_warn "Could not verify tempdb space"
    fi

    # Check tier scripts exist
    local tier_start="${TIER_START}"
    local tier_end="${TIER_END}"

    # Default to all tiers if not specified
    if [[ ${tier_start} -eq -1 ]]; then
        tier_start=0
        tier_end=4
    fi

    log_info "Validating tier scripts (${tier_start}-${tier_end})..."
    for tier in $(seq "${tier_start}" "${tier_end}"); do
        local script_file="${SCRIPT_DIR}/extract-tier-${tier}.sql"
        if [[ ! -f "${script_file}" ]]; then
            error_exit "Missing tier script: ${script_file}"
        fi
        log_debug "  Found: extract-tier-${tier}.sql"
    done
    log_success "All required tier scripts found"
}

# -----------------------------------------------------------------------------
# CSV BACKUP
# -----------------------------------------------------------------------------

backup_existing_csvs() {
    print_section "Backing Up Existing CSVs"

    local csv_count
    csv_count=$(find "${DATA_DIR}" -maxdepth 1 -type f -name "*.csv" 2>/dev/null | wc -l)

    if [[ ${csv_count} -eq 0 ]]; then
        log_info "No existing CSVs to backup"
        return 0
    fi

    local backup_dir="${DATA_DIR}/backup-${TIMESTAMP}"
    mkdir -p "${backup_dir}" || error_exit "Failed to create backup directory: ${backup_dir}"

    log_info "Backing up ${csv_count} CSV files to: ${backup_dir}"

    if mv "${DATA_DIR}"/*.csv "${backup_dir}/" 2>> "${LOG_FILE}"; then
        log_success "CSVs backed up successfully"
    else
        log_warn "Some CSVs could not be backed up"
    fi
}

# -----------------------------------------------------------------------------
# TIER EXECUTION
# -----------------------------------------------------------------------------

execute_tier() {
    local tier="$1"
    local script_file="${SCRIPT_DIR}/extract-tier-${tier}.sql"

    print_section "Executing Tier ${tier}"

    log_info "Script: ${script_file}"
    log_info "Timeout: ${TIMEOUT}s"

    if [[ ${DRY_RUN} -eq 1 ]]; then
        log_info "[DRY RUN] Would execute: ${script_file}"
        return 0
    fi

    local tier_start_time
    tier_start_time=$(date +%s)

    # Execute tier script
    log_info "Executing SQL script..."
    if ! sqlcmd -S "${SQL_SERVER}" -U "${SQL_USER}" -P "${SQL_PASSWORD}" \
        -d "${SQL_DATABASE}" -b -t "${TIMEOUT}" \
        -i "${script_file}" >> "${LOG_FILE}" 2>&1; then
        error_exit "Tier ${tier} execution failed. Check log: ${LOG_FILE}"
    fi

    local tier_duration=$(($(date +%s) - tier_start_time))
    log_success "Tier ${tier} completed in ${tier_duration}s"
}

execute_combined_tiers_sql() {
    local tier_start="$1"
    local tier_end="$2"
    local combined_script="${SCRIPT_DIR}/.tmp-combined-tiers-${TIMESTAMP}.sql"

    print_section "Executing Combined Tiers (${tier_start}-${tier_end}) in Single Session"

    log_info "Strategy: Option A - Single SQL session for all tiers"
    log_info "Timeout: ${TIMEOUT}s"

    if [[ ${DRY_RUN} -eq 1 ]]; then
        log_info "[DRY RUN] Would execute combined tiers ${tier_start}-${tier_end}"
        return 0
    fi

    # Validate all tier scripts exist
    log_info "Validating tier scripts..."
    for tier in $(seq "${tier_start}" "${tier_end}"); do
        local script_file="${SCRIPT_DIR}/extract-tier-${tier}.sql"
        if [[ ! -f "${script_file}" ]]; then
            error_exit "Missing tier script: ${script_file}"
        fi
    done
    log_success "All tier scripts validated"

    # Create combined script
    log_info "Creating combined SQL script..."
    {
        echo "-- ============================================================================="
        echo "-- Combined Tier Execution (Tiers ${tier_start}-${tier_end})"
        echo "-- Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "-- Strategy: Single session to preserve global temp tables (##)"
        echo "-- ============================================================================="
        echo ""
        echo "SET NOCOUNT ON;"
        echo "GO"
        echo ""

        for tier in $(seq "${tier_start}" "${tier_end}"); do
            local script_file="${SCRIPT_DIR}/extract-tier-${tier}.sql"
            echo "-- ============================================================================="
            echo "-- TIER ${tier}: ${script_file}"
            echo "-- ============================================================================="
            echo ""
            cat "${script_file}"
            echo ""
            echo "GO"
            echo ""
        done

        echo "-- ============================================================================="
        echo "-- Combined execution completed"
        echo "-- ============================================================================="
        echo ""
        echo "-- ============================================================================="
        echo "-- SESSION KEEPALIVE - Preserve global temp tables for CSV export"
        echo "-- ============================================================================="
        echo "PRINT 'SQL extraction complete. Keeping session alive for CSV export...';"
        echo "PRINT 'Session will auto-terminate in 30 minutes if export does not complete.';"
        echo "PRINT '';"
        echo "PRINT 'READY_FOR_EXPORT';"
        echo "GO"
        echo ""
        echo "-- Wait 270 minutes (allows time for BCP export from client)"
        echo "WAITFOR DELAY '04:30:00';"
        echo "GO"
        echo ""
        echo "PRINT 'Session keepalive timeout reached. Exiting.';"
    } > "${combined_script}"

    if [[ ! -f "${combined_script}" ]]; then
        error_exit "Failed to create combined script: ${combined_script}"
    fi

    # Validate combined script size
    local script_lines
    script_lines=$(wc -l < "${combined_script}" | tr -d '[:space:]')
    log_info "Combined script: ${script_lines} lines"

    if [[ ${script_lines} -lt 100 ]]; then
        error_exit "Combined script too small (${script_lines} lines). Possible concatenation failure."
    fi

    log_success "Combined script created: ${combined_script}"

    # Execute combined script in single session
    local execution_start_time
    execution_start_time=$(date +%s)

    log_info "Launching SQL extraction in background (session will remain active)..."
    log_info "NOTE: Global temp tables (##) will persist across all tiers and CSV export"

    # Execute combined script in background, monitor for READY_FOR_EXPORT signal
    # NOTE: Using ${TIMEOUT} from .env (SQL_TIMEOUT) to control session lifetime
    # Recommended: Set SQL_TIMEOUT=21600 (6 hours) in .env for large table exports
    # For development with TOP 5000 limit, SQL_TIMEOUT=3600 (1 hour) is sufficient
    sqlcmd -S "${SQL_SERVER}" -U "${SQL_USER}" -P "${SQL_PASSWORD}" \
        -d "${SQL_DATABASE}" -b -t "${TIMEOUT}" \
        -i "${combined_script}" 2>&1 | tee -a "${LOG_FILE}" | {
        # Monitor output for "READY_FOR_EXPORT" signal
        while IFS= read -r line; do
            if [[ "${line}" =~ READY_FOR_EXPORT ]]; then
                # Signal detected - trigger CSV export
                touch "${SCRIPT_DIR}/.export-ready-${TIMESTAMP}"
                log_success "SQL extraction complete. Triggering CSV export..."
            fi
        done
    } &

    SQL_SESSION_PID=$!
    log_info "SQL session running in background (PID: ${SQL_SESSION_PID})"

    # Wait for export-ready signal (timeout after 15 minutes)
    log_info "Waiting for SQL extraction to complete..."
    local wait_start=$(date +%s)
    local wait_timeout=3600  # 1 hour

    while [[ ! -f "${SCRIPT_DIR}/.export-ready-${TIMESTAMP}" ]]; do
        sleep 5
        local wait_elapsed=$(($(date +%s) - wait_start))

        if [[ ${wait_elapsed} -gt ${wait_timeout} ]]; then
            log_error "Timeout waiting for SQL extraction (${wait_timeout}s)"
            kill ${SQL_SESSION_PID} 2>/dev/null || true
            error_exit "SQL extraction timeout"
        fi

        # Check if SQL session crashed
        if ! ps -p ${SQL_SESSION_PID} > /dev/null 2>&1; then
            log_error "SQL session terminated unexpectedly"
            error_exit "SQL extraction failed (check log)"
        fi
    done

    log_success "SQL extraction complete. Session active. Starting CSV export..."

    local execution_duration=$(($(date +%s) - execution_start_time))
    log_success "Combined tiers (${tier_start}-${tier_end}) completed in ${execution_duration}s"

    # Clean up combined script
    if rm -f "${combined_script}" 2>> "${LOG_FILE}"; then
        log_debug "Cleaned up temporary combined script"
    else
        log_warn "Could not remove temporary script: ${combined_script}"
    fi
}

# -----------------------------------------------------------------------------
# CSV EXPORT
# -----------------------------------------------------------------------------

export_temp_table_to_csv() {
    local table_name="$1"
    local csv_file="${DATA_DIR}/${table_name}.csv"

    # Health check: Verify SQL session still alive (if background session exists)
    if [[ -n "${SQL_SESSION_PID}" ]] && ! ps -p ${SQL_SESSION_PID} > /dev/null 2>&1; then
        log_error "SQL session crashed during CSV export (PID: ${SQL_SESSION_PID})"
        error_exit "SQL session terminated unexpectedly"
    fi

    log_info "Exporting ${table_name} to CSV..."

    if [[ ${DRY_RUN} -eq 1 ]]; then
        log_info "[DRY RUN] Would export: ${table_name} -> ${csv_file}"
        return 0
    fi

    # Export using bcp
    if ! bcp "tempdb..${table_name}" out "${csv_file}" \
        -S "${SQL_SERVER}" -U "${SQL_USER}" -P "${SQL_PASSWORD}" \
        -c -t ',' -r '\n' -b 10000 >> "${LOG_FILE}" 2>&1; then
        log_error "Failed to export ${table_name}"
        return 1
    fi

    # Validate CSV file
    if [[ ! -f "${csv_file}" ]]; then
        log_error "CSV file not created: ${csv_file}"
        return 1
    fi

    local file_size
    file_size=$(stat -f%z "${csv_file}" 2>/dev/null || stat -c%s "${csv_file}" 2>/dev/null || echo "0")

    if [[ ${file_size} -eq 0 ]]; then
        log_warn "CSV file is empty: ${csv_file} (0 rows in source table)"
        return 0  # Empty tables are valid, not an error
    fi

    local file_size_mb
    file_size_mb=$(echo "scale=2; ${file_size} / 1024 / 1024" | bc)

    # Count rows (approximate)
    local row_count
    row_count=$(wc -l < "${csv_file}" | tr -d '[:space:]')

    STATS_TABLES_PROCESSED=$((STATS_TABLES_PROCESSED + 1))
    STATS_TOTAL_ROWS=$((STATS_TOTAL_ROWS + row_count))
    STATS_TOTAL_CSV_SIZE=$((STATS_TOTAL_CSV_SIZE + file_size))

    log_success "  Exported: ${row_count} rows, ${file_size_mb} MB"

    return 0
}

export_tier_csvs() {
    local tier="$1"

    print_section "Exporting Tier ${tier} CSVs"

    # Query tempdb for temp tables created by this tier
    log_info "Discovering temp tables in tempdb..."

    local temp_tables_query="
    SET NOCOUNT ON;
    SELECT name
    FROM tempdb.sys.tables
    WHERE name LIKE '##perseus_tier_${tier}_%'
    ORDER BY name;
    "

    local tables
    mapfile -t tables < <(sqlcmd -S "${SQL_SERVER}" -U "${SQL_USER}" -P "${SQL_PASSWORD}" \
        -d tempdb -h -1 -W -b -m 1 \
        -Q "${temp_tables_query}" 2>> "${LOG_FILE}" | grep -E '^##perseus_tier_' | sed '/^$/d')

    if [[ ${#tables[@]} -eq 0 ]]; then
        log_warn "No temp tables found for tier ${tier}"
        return 0
    fi

    log_info "Found ${#tables[@]} temp tables to export"

    for table in "${tables[@]}"; do
        # Trim whitespace
        table=$(echo "${table}" | xargs)

        if [[ -n "${table}" ]]; then
            TEMP_TABLES+=("${table}")
            export_temp_table_to_csv "${table}" || {
                log_warn "Export failed for ${table}, continuing with next table..."
            }
        fi
    done

    log_success "Tier ${tier} CSV export completed"
}

export_all_tiers_csvs() {
    local tier_start="$1"
    local tier_end="$2"

    print_section "Exporting All Tiers (${tier_start}-${tier_end}) CSVs"

    local export_start_time=$(date +%s)

    log_info "Strategy: Export all temp tables created by combined execution"
    log_info "NOTE: Using new session - temp tables must be global (##) to persist"

    # Query tempdb for all temp tables across all tiers
    log_info "Discovering temp tables in tempdb..."

    local temp_tables_query="
    SET NOCOUNT ON;
    SELECT name
    FROM tempdb.sys.tables
    WHERE name LIKE '##perseus_tier_%'
    ORDER BY name;
    "

    local tables
    mapfile -t tables < <(sqlcmd -S "${SQL_SERVER}" -U "${SQL_USER}" -P "${SQL_PASSWORD}" \
        -d tempdb -h -1 -W -b -m 1 \
        -Q "${temp_tables_query}" 2>> "${LOG_FILE}" | grep -E '^##perseus_tier_' | sed '/^$/d')

    if [[ ${#tables[@]} -eq 0 ]]; then
        log_error "No temp tables found for tiers ${tier_start}-${tier_end}"
        log_error "This indicates the global temp tables (##) were not created or have been dropped"
        error_exit "CSV export failed: no temp tables found"
    fi

    log_info "Found ${#tables[@]} temp tables to export across all tiers"

    # Group by tier for logging
    local tier_counts=()
    for tier in $(seq "${tier_start}" "${tier_end}"); do
        local count=0
        for table in "${tables[@]}"; do
            if [[ "${table}" =~ ^##perseus_tier_${tier}_ ]]; then
                count=$((count + 1))
            fi
        done
        if [[ ${count} -gt 0 ]]; then
            log_info "  Tier ${tier}: ${count} tables"
        fi
    done

    # Export all tables
    for table in "${tables[@]}"; do
        # Trim whitespace
        table=$(echo "${table}" | xargs)

        if [[ -n "${table}" ]]; then
            TEMP_TABLES+=("${table}")
            export_temp_table_to_csv "${table}" || {
                log_warn "Export failed for ${table}, continuing with next table..."
            }
        fi
    done

    local export_duration=$(($(date +%s) - export_start_time))
    log_success "All tiers (${tier_start}-${tier_end}) CSV export completed in ${export_duration}s"

    # Terminate background SQL session (temp tables no longer needed)
    if [[ -n "${SQL_SESSION_PID}" ]] && ps -p ${SQL_SESSION_PID} > /dev/null 2>&1; then
        log_info "Terminating SQL session (PID: ${SQL_SESSION_PID})..."
        kill ${SQL_SESSION_PID} 2>> "${LOG_FILE}" || log_warn "Could not kill SQL session PID ${SQL_SESSION_PID}"
        log_success "SQL session terminated"
    else
        log_debug "SQL session already exited"
    fi

    # Cleanup signal file
    if [[ -f "${SCRIPT_DIR}/.export-ready-${TIMESTAMP}" ]]; then
        rm -f "${SCRIPT_DIR}/.export-ready-${TIMESTAMP}" 2>> "${LOG_FILE}"
        log_debug "Cleaned up signal file"
    fi
}

# -----------------------------------------------------------------------------
# SUMMARY REPORT
# -----------------------------------------------------------------------------

generate_summary() {
    print_header "EXTRACTION SUMMARY"

    local total_duration=$(($(date +%s) - STATS_START_TIME))
    local total_csv_size_mb
    total_csv_size_mb=$(echo "scale=2; ${STATS_TOTAL_CSV_SIZE} / 1024 / 1024" | bc)

    echo ""
    echo -e "${COLOR_BOLD}Execution Statistics:${COLOR_RESET}"
    echo "  Duration:         ${total_duration}s ($(date -u -r ${total_duration} '+%H:%M:%S' 2>/dev/null || echo 'N/A'))"
    echo "  Tables Processed: ${STATS_TABLES_PROCESSED}"
    echo "  Total Rows:       ${STATS_TOTAL_ROWS}"
    echo "  Total CSV Size:   ${total_csv_size_mb} MB"
    echo ""
    echo -e "${COLOR_BOLD}Output Locations:${COLOR_RESET}"
    echo "  CSV Files:        ${DATA_DIR}/"
    echo "  Log File:         ${LOG_FILE}"
    echo ""

    if [[ ${DRY_RUN} -eq 1 ]]; then
        echo -e "${COLOR_YELLOW}[DRY RUN] No actual data extracted${COLOR_RESET}"
    else
        echo -e "${COLOR_GREEN}Data extraction completed successfully!${COLOR_RESET}"
    fi
    echo ""

    log INFO "=== SUMMARY ==="
    log INFO "Duration: ${total_duration}s"
    log INFO "Tables: ${STATS_TABLES_PROCESSED}"
    log INFO "Rows: ${STATS_TOTAL_ROWS}"
    log INFO "CSV Size: ${total_csv_size_mb} MB"
}

# -----------------------------------------------------------------------------
# MAIN EXECUTION
# -----------------------------------------------------------------------------

main() {
    print_header "Perseus Data Extraction Orchestrator"

    log_info "Script started: ${SCRIPT_NAME}"
    log_info "Timestamp: ${TIMESTAMP}"
    log_info "Working directory: ${SCRIPT_DIR}"

    # Initialize
    STATS_START_TIME=$(date +%s)

    # Cleanup old signal files from previous runs
    rm -f "${SCRIPT_DIR}"/.export-ready-* 2>> "${LOG_FILE}"
    log_debug "Cleaned up old signal files"

    # Load configuration FIRST (.env-first precedence)
    load_environment

    # Parse arguments SECOND (CLI flags override .env)
    parse_arguments "$@"

    # Update LOG_FILE if LOG_DIR was changed by CLI flag
    # (Currently no --log-dir flag, but future-proofing)
    LOG_FILE="${LOG_DIR}/extract-data-${TIMESTAMP}.log"

    # Prerequisite checks
    check_prerequisites

    # Determine tier range
    local tier_start="${TIER_START}"
    local tier_end="${TIER_END}"

    if [[ ${tier_start} -eq -1 ]]; then
        tier_start=0
        tier_end=4
        log_info "Executing all tiers (0-4)"
    else
        log_info "Executing tiers ${tier_start}-${tier_end}"
    fi

    # Backup existing CSVs
    if [[ ${DRY_RUN} -eq 0 ]]; then
        backup_existing_csvs
    fi

    # Execute tiers
    # Use combined execution for full tier range (0-4) to preserve global temp tables
    # Use individual execution for partial ranges or single tiers
    if [[ ${tier_start} -eq 0 && ${tier_end} -eq 4 ]]; then
        log_info "Using combined execution strategy (Option A) for all tiers"
        execute_combined_tiers_sql "${tier_start}" "${tier_end}"
        export_all_tiers_csvs "${tier_start}" "${tier_end}"
    else
        log_info "Using individual tier execution for partial range"
        log_warn "NOTE: Global temp tables (##) may not persist between tiers"
        for tier in $(seq "${tier_start}" "${tier_end}"); do
            execute_tier "${tier}"
            export_tier_csvs "${tier}"
        done
    fi

    # Generate summary
    generate_summary

    exit 0
}

# -----------------------------------------------------------------------------
# SCRIPT ENTRY POINT
# -----------------------------------------------------------------------------

main "$@"
