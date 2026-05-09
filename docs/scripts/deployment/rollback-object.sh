#!/usr/bin/env bash
#
# Perseus Database Migration - Object Rollback Script
#
# This script provides object-level rollback capability for database deployments.
# Supports rolling back procedures, functions, views, indexes, and constraints to
# their previous state using backup files created during deployment.
#
# Usage:
#   ./rollback-object.sh <object_type> <object_name> [environment] [options]
#
# Arguments:
#   object_type    Type of object: procedure, function, view, index, constraint, table
#   object_name    Schema-qualified name (e.g., perseus.reconcilemupstream)
#   environment    Target environment: dev, qa, staging, prod (default: dev)
#
# Options:
#   --backup-file <path>    Specify backup file explicitly
#   --emergency            Emergency mode: skip validation, use fastest path
#   --force                Force rollback without confirmation
#   --skip-validation      Skip post-rollback validation
#   --help                 Show this help message
#
# Rollback Strategies:
#   - Procedures/Functions/Views: DROP IF EXISTS + CREATE from backup
#   - Indexes: DROP INDEX + recreate from backup DDL
#   - Constraints: ALTER TABLE DROP CONSTRAINT + recreate from backup DDL
#   - Tables: MANUAL ONLY (complex - documented limitations)
#
# Backup Locations (searched in order):
#   1. ${BACKUP_DIR}/<object_type>/<object_name>_<timestamp>.sql
#   2. ${BACKUP_DIR}/<object_type>/<object_name>_latest.sql
#   3. Git history (previous commit of object file)
#
# Exit Codes:
#   0 - Rollback successful
#   1 - Rollback failed
#   2 - Invalid arguments or missing backup
#   3 - Post-rollback validation failed
#
# Examples:
#   # Rollback procedure in DEV
#   ./rollback-object.sh procedure perseus.reconcilemupstream dev
#
#   # Rollback view in PROD with confirmation
#   ./rollback-object.sh view perseus.v_material_lineage prod
#
#   # Emergency rollback (no validation)
#   ./rollback-object.sh function perseus.mcgetupstream prod --emergency
#
#   # Rollback using specific backup file
#   ./rollback-object.sh procedure perseus.addarc qa --backup-file /path/to/backup.sql
#
# Requirements:
#   - PostgreSQL 17+ client (psql)
#   - Docker (optional - for containerized database)
#   - Backup files created by deploy-object.sh
#   - Appropriate database permissions (DROP, CREATE)
#
# Rollback Window:
#   - 7 days post-deployment (aligned with AS-014, CN-023)
#   - After 7 days, backups are archived and rollback requires manual recovery
#
# Constitution Compliance:
#   - Article VII: Modular Logic Separation (object-level rollback)
#   - Atomic operations (BEGIN/COMMIT/ROLLBACK)
#   - Structured error handling with context
#   - POSIX-compliant bash (set -euo pipefail)
#
# Created: 2026-01-25
# Author: Claude Code (database-expert agent)
# Maintained by: Pierre Ribeiro (DBA/DBRE)
#

# Future Enhancements Backlog Section
# 1. Create an env.conf or .json file for setting up script initial variables
# 2. Password are read from secrets file path at configuration file
# 3. Execution logs must be written in the global temporary directory informed in configuration file.
# 4. Directory logs tree pattern: {global_dir}/{branch_name}/{dir_script_souce}/file_name_{timestamp}.log
# 5. Review the entire scipt looking for bug or flaws in the execution logic, explore edge cases

set -euo pipefail

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default configuration
DEFAULT_ENVIRONMENT="dev"
BACKUP_DIR="${SCRIPT_DIR}/backups"  # Match deploy-object.sh backup location
LOGS_DIR="${PROJECT_ROOT}/logs/deployment"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOGS_DIR}/rollback_${TIMESTAMP}.log"

# Database connection parameters
DB_USER="${DB_USER:-perseus_admin}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
PGPASSWORD_FILE="${PGPASSWORD_FILE:-${PROJECT_ROOT}/infra/database/.secrets/postgres_password.txt}"
DOCKER_CONTAINER="${DOCKER_CONTAINER:-perseus-postgres-dev}"

# Execution mode (auto-detected)
USE_DOCKER=false

# Rollback mode flags
EMERGENCY_MODE=false
FORCE_MODE=false
SKIP_VALIDATION=false
EXPLICIT_BACKUP_FILE=""

# Counters and state
ROLLBACK_SUCCESS=false
BACKUP_FOUND=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    local msg="$1"
    echo -e "${BLUE}[INFO]${NC} ${msg}" | tee -a "${LOG_FILE}"
}

log_success() {
    local msg="$1"
    echo -e "${GREEN}[✓ SUCCESS]${NC} ${msg}" | tee -a "${LOG_FILE}"
}

log_error() {
    local msg="$1"
    echo -e "${RED}[✗ ERROR]${NC} ${msg}" | tee -a "${LOG_FILE}"
}

log_warning() {
    local msg="$1"
    echo -e "${YELLOW}[⚠ WARNING]${NC} ${msg}" | tee -a "${LOG_FILE}"
}

log_section() {
    local msg="$1"
    echo "" | tee -a "${LOG_FILE}"
    echo -e "${CYAN}=========================================================================${NC}" | tee -a "${LOG_FILE}"
    echo -e "${CYAN}${msg}${NC}" | tee -a "${LOG_FILE}"
    echo -e "${CYAN}=========================================================================${NC}" | tee -a "${LOG_FILE}"
}

log_emergency() {
    local msg="$1"
    echo -e "${MAGENTA}[🚨 EMERGENCY]${NC} ${msg}" | tee -a "${LOG_FILE}"
}

# Show usage
show_usage() {
    cat << 'EOF'
Perseus Database Migration - Object Rollback Script

Usage:
  ./rollback-object.sh <object_type> <object_name> [environment] [options]

Arguments:
  object_type    Type: procedure, function, view, index, constraint, table
  object_name    Schema-qualified name (e.g., perseus.reconcilemupstream)
  environment    Target: dev, qa, staging, prod (default: dev)

Options:
  --backup-file <path>    Specify backup file explicitly
  --emergency            Emergency mode: skip validation
  --force                Force rollback without confirmation
  --skip-validation      Skip post-rollback validation
  --help                 Show this help message

Examples:
  ./rollback-object.sh procedure perseus.reconcilemupstream dev
  ./rollback-object.sh view perseus.v_material_lineage prod --force
  ./rollback-object.sh function perseus.mcgetupstream prod --emergency

Supported Object Types:
  - procedure       Stored procedures
  - function        Functions (table-valued, scalar)
  - view            Views (standard, materialized)
  - index           Indexes
  - constraint      Constraints (PK, FK, CHECK, UNIQUE)
  - table           Tables (MANUAL RECOVERY - see documentation)

Rollback Window: 7 days (aligned with AS-014, CN-023)

Exit Codes:
  0 - Success
  1 - Rollback failed
  2 - Invalid arguments or missing backup
  3 - Post-rollback validation failed
EOF
}

# Initialize logging
init_logging() {
    mkdir -p "${LOGS_DIR}"

    log_section "PERSEUS DATABASE MIGRATION - OBJECT ROLLBACK"
    log_info "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    log_info "User: ${USER}"
    log_info "Hostname: $(hostname)"
    log_info "Log file: ${LOG_FILE}"
}

# Detect execution mode (local psql or Docker)
detect_execution_mode() {
    # Check if psql is available locally
    if command -v psql > /dev/null 2>&1; then
        USE_DOCKER=false
        log_info "Execution mode: Local psql client"
    # Check if Docker is available and container is running
    elif command -v docker > /dev/null 2>&1; then
        if docker ps --filter "name=${DOCKER_CONTAINER}" --format "{{.Names}}" | grep -q "${DOCKER_CONTAINER}"; then
            USE_DOCKER=true
            log_info "Execution mode: Docker container (${DOCKER_CONTAINER})"
        else
            log_error "PostgreSQL container not running: ${DOCKER_CONTAINER}"
            log_info "Start container: cd infra/database && ./init-db.sh start"
            exit 2
        fi
    else
        log_error "Neither psql nor Docker is available"
        log_info "Install PostgreSQL client: brew install postgresql@17"
        log_info "Or ensure Docker is installed and running"
        exit 2
    fi
}

# Execute psql command (local or Docker)
run_psql() {
    if [[ "${USE_DOCKER}" == "true" ]]; then
        docker exec -i "${DOCKER_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" "$@"
    else
        export PGPASSWORD=$(cat "${PGPASSWORD_FILE}")
        psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" "$@"
    fi
}

# Execute psql command from file (handles Docker file copy)
run_psql_file() {
    local file="$1"

    if [[ "${USE_DOCKER}" == "true" ]]; then
        local container_temp="/tmp/rollback_$(basename "${file}")"
        docker cp "${file}" "${DOCKER_CONTAINER}:${container_temp}" 2>/dev/null

        if docker exec -i "${DOCKER_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" \
             -f "${container_temp}" 2>&1; then
            docker exec "${DOCKER_CONTAINER}" rm -f "${container_temp}" 2>/dev/null || true
            return 0
        else
            docker exec "${DOCKER_CONTAINER}" rm -f "${container_temp}" 2>/dev/null || true
            return 1
        fi
    else
        export PGPASSWORD=$(cat "${PGPASSWORD_FILE}")
        psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${file}" 2>&1
    fi
}

# Load database password (only for local mode)
load_password() {
    if [[ "${USE_DOCKER}" == "false" ]]; then
        if [[ ! -f "${PGPASSWORD_FILE}" ]]; then
            log_error "Password file not found: ${PGPASSWORD_FILE}"
            log_info "Run: cd infra/database && ./init-db.sh setup"
            exit 2
        fi
        export PGPASSWORD=$(cat "${PGPASSWORD_FILE}")
    fi
}

# Check database connection
check_database() {
    log_info "Checking database connection: ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

    if ! run_psql -c "SELECT version();" > /dev/null 2>&1; then
        log_error "Cannot connect to database: ${DB_NAME}"
        log_info "Ensure PostgreSQL container is running: cd infra/database && ./init-db.sh start"
        exit 2
    fi

    local pg_version=$(run_psql -t -c "SHOW server_version;" | xargs)
    log_success "Database connection OK (PostgreSQL ${pg_version})"
}

# Validate object type
validate_object_type() {
    local obj_type="$1"

    case "${obj_type}" in
        procedure|function|view|index|constraint|table)
            return 0
            ;;
        *)
            log_error "Invalid object type: ${obj_type}"
            log_info "Supported types: procedure, function, view, index, constraint, table"
            return 1
            ;;
    esac
}

# Parse object name into schema and object
parse_object_name() {
    local full_name="$1"

    if [[ "${full_name}" == *"."* ]]; then
        SCHEMA_NAME="${full_name%%.*}"
        OBJECT_NAME="${full_name#*.}"
    else
        SCHEMA_NAME="perseus"
        OBJECT_NAME="${full_name}"
        log_warning "No schema specified, using default: ${SCHEMA_NAME}"
    fi

    log_info "Schema: ${SCHEMA_NAME}"
    log_info "Object: ${OBJECT_NAME}"
}

# Find backup file
find_backup_file() {
    local obj_type="$1"
    local obj_name="$2"

    log_info "Searching for backup file..."

    # If explicit backup file provided, use it
    if [[ -n "${EXPLICIT_BACKUP_FILE}" ]]; then
        if [[ -f "${EXPLICIT_BACKUP_FILE}" ]]; then
            BACKUP_FILE="${EXPLICIT_BACKUP_FILE}"
            BACKUP_FOUND=true
            log_success "Using explicit backup: ${BACKUP_FILE}"
            return 0
        else
            log_error "Explicit backup file not found: ${EXPLICIT_BACKUP_FILE}"
            return 1
        fi
    fi

    # Search in backup directory
    local backup_base="${BACKUP_DIR}/${obj_type}"

    # Strategy 1: Find most recent timestamped backup (within 7 days)
    if [[ -d "${backup_base}" ]]; then
        local cutoff_date=$(date -v-7d +%Y%m%d 2>/dev/null || date -d '7 days ago' +%Y%m%d)
        local latest_backup=$(find "${backup_base}" -type f -name "${obj_name}_*.sql" -print0 | \
            xargs -0 ls -t 2>/dev/null | head -n 1)

        if [[ -n "${latest_backup}" && -f "${latest_backup}" ]]; then
            # Extract timestamp from filename
            local backup_timestamp=$(basename "${latest_backup}" | grep -oE '[0-9]{8}_[0-9]{6}' || echo "")

            if [[ -n "${backup_timestamp}" ]]; then
                local backup_date="${backup_timestamp%%_*}"

                # Check if backup is within 7-day window
                if [[ "${backup_date}" -ge "${cutoff_date}" ]]; then
                    BACKUP_FILE="${latest_backup}"
                    BACKUP_FOUND=true
                    log_success "Found recent backup: ${BACKUP_FILE}"
                    return 0
                else
                    log_warning "Backup found but older than 7 days: ${latest_backup}"
                    log_warning "Backup date: ${backup_date}, Cutoff: ${cutoff_date}"
                fi
            fi
        fi
    fi

    # Strategy 2: Check for _latest.sql symlink
    local latest_link="${backup_base}/${obj_name}_latest.sql"
    if [[ -f "${latest_link}" ]]; then
        BACKUP_FILE="${latest_link}"
        BACKUP_FOUND=true
        log_success "Found latest backup link: ${BACKUP_FILE}"
        return 0
    fi

    # Strategy 3: Search in git history (if in git repo)
    if git -C "${PROJECT_ROOT}" rev-parse --git-dir > /dev/null 2>&1; then
        log_info "Attempting to locate object in git history..."

        # Try to find the object file in source tree
        local source_file=$(find "${PROJECT_ROOT}/source/building/pgsql/refactored" \
            -type f -name "*${obj_name}*.sql" 2>/dev/null | head -n 1)

        if [[ -n "${source_file}" && -f "${source_file}" ]]; then
            log_info "Found object file: ${source_file}"
            log_warning "Using current source file as backup (NOT from git history)"
            BACKUP_FILE="${source_file}"
            BACKUP_FOUND=true
            return 0
        fi
    fi

    # No backup found
    log_error "No backup file found for ${obj_type}: ${obj_name}"
    log_info "Searched locations:"
    log_info "  - ${backup_base}/${obj_name}_*.sql (within 7 days)"
    log_info "  - ${backup_base}/${obj_name}_latest.sql"
    log_info "  - Git history (source files)"
    return 1
}

# Confirm rollback action
confirm_rollback() {
    local obj_type="$1"
    local obj_name="$2"
    local env="$3"

    if [[ "${FORCE_MODE}" == "true" ]]; then
        log_warning "Force mode enabled - skipping confirmation"
        return 0
    fi

    if [[ "${EMERGENCY_MODE}" == "true" ]]; then
        log_emergency "Emergency mode enabled - skipping confirmation"
        return 0
    fi

    log_section "ROLLBACK CONFIRMATION"
    echo ""
    echo -e "${YELLOW}WARNING: You are about to rollback the following object:${NC}"
    echo ""
    echo -e "  Object Type:  ${obj_type}"
    echo -e "  Object Name:  ${SCHEMA_NAME}.${OBJECT_NAME}"
    echo -e "  Environment:  ${env} (${DB_NAME})"
    echo -e "  Backup File:  ${BACKUP_FILE}"
    echo ""
    echo -e "${YELLOW}This will DROP the current object and restore from backup.${NC}"
    echo ""

    read -p "Continue with rollback? (yes/NO): " -r
    echo ""

    if [[ ! "${REPLY}" =~ ^[Yy][Ee][Ss]$ ]]; then
        log_warning "Rollback cancelled by user"
        exit 0
    fi

    log_success "Rollback confirmed by user"
}

# Rollback procedure or function
rollback_procedure_or_function() {
    local obj_type="$1"
    local obj_name="${SCHEMA_NAME}.${OBJECT_NAME}"

    log_section "ROLLING BACK ${obj_type^^}: ${obj_name}"

    # Create rollback transaction script
    local rollback_script=$(mktemp)
    trap "rm -f ${rollback_script}" RETURN

    cat > "${rollback_script}" << EOF
-- Rollback ${obj_type}: ${obj_name}
-- Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
-- Backup: ${BACKUP_FILE}

BEGIN;

-- Set error handling
\set ON_ERROR_STOP on

-- Drop existing ${obj_type}
DROP ${obj_type^^} IF EXISTS ${obj_name} CASCADE;

-- Restore from backup
\ir ${BACKUP_FILE}

COMMIT;
EOF

    log_info "Executing rollback..."

    if run_psql_file "${rollback_script}"; then
        log_success "${obj_type^} rolled back successfully: ${obj_name}"
        ROLLBACK_SUCCESS=true
        return 0
    else
        log_error "${obj_type^} rollback failed"
        ROLLBACK_SUCCESS=false
        return 1
    fi
}

# Rollback view
rollback_view() {
    local obj_name="${SCHEMA_NAME}.${OBJECT_NAME}"

    log_section "ROLLING BACK VIEW: ${obj_name}"

    # Check if it's a materialized view
    local is_materialized=$(run_psql -t -c \
        "SELECT COUNT(*) FROM pg_matviews WHERE schemaname = '${SCHEMA_NAME}' AND matviewname = '${OBJECT_NAME}';" \
        2>/dev/null | xargs || echo "0")

    local view_type="VIEW"
    if [[ "${is_materialized}" -gt 0 ]]; then
        view_type="MATERIALIZED VIEW"
        log_info "Detected materialized view"
    fi

    # Create rollback transaction script
    local rollback_script=$(mktemp)
    trap "rm -f ${rollback_script}" RETURN

    cat > "${rollback_script}" << EOF
-- Rollback view: ${obj_name}
-- Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
-- Backup: ${BACKUP_FILE}

BEGIN;

-- Set error handling
\set ON_ERROR_STOP on

-- Drop existing view
DROP ${view_type} IF EXISTS ${obj_name} CASCADE;

-- Restore from backup
\ir ${BACKUP_FILE}

COMMIT;
EOF

    log_info "Executing rollback..."

    if run_psql_file "${rollback_script}"; then
        log_success "View rolled back successfully: ${obj_name}"
        ROLLBACK_SUCCESS=true
        return 0
    else
        log_error "View rollback failed"
        ROLLBACK_SUCCESS=false
        return 1
    fi
}

# Rollback index
rollback_index() {
    local obj_name="${OBJECT_NAME}"

    log_section "ROLLING BACK INDEX: ${obj_name}"

    # Create rollback transaction script
    local rollback_script=$(mktemp)
    trap "rm -f ${rollback_script}" RETURN

    cat > "${rollback_script}" << EOF
-- Rollback index: ${obj_name}
-- Timestamp: $(date '+%Y-%m-%d %H:%M:%S')
-- Backup: ${BACKUP_FILE}

BEGIN;

-- Set error handling
\set ON_ERROR_STOP on

-- Drop existing index
DROP INDEX IF EXISTS ${SCHEMA_NAME}.${obj_name} CASCADE;

-- Restore from backup
\ir ${BACKUP_FILE}

COMMIT;
EOF

    log_info "Executing rollback..."

    if run_psql_file "${rollback_script}"; then
        log_success "Index rolled back successfully: ${obj_name}"
        ROLLBACK_SUCCESS=true
        return 0
    else
        log_error "Index rollback failed"
        ROLLBACK_SUCCESS=false
        return 1
    fi
}

# Rollback constraint
rollback_constraint() {
    local obj_name="${OBJECT_NAME}"

    log_section "ROLLING BACK CONSTRAINT: ${obj_name}"

    log_warning "Constraint rollback requires manual intervention"
    log_info "Backup file: ${BACKUP_FILE}"
    log_info "Steps:"
    log_info "  1. Review constraint definition in backup file"
    log_info "  2. Identify table: grep 'ALTER TABLE' ${BACKUP_FILE}"
    log_info "  3. Drop constraint: ALTER TABLE <table> DROP CONSTRAINT ${obj_name};"
    log_info "  4. Recreate: Execute DDL from backup file"

    if [[ "${FORCE_MODE}" == "true" ]]; then
        log_warning "Force mode enabled - attempting automatic rollback"

        # Try to execute backup file directly
        if run_psql_file "${BACKUP_FILE}"; then
            log_success "Constraint rolled back successfully: ${obj_name}"
            ROLLBACK_SUCCESS=true
            return 0
        else
            log_error "Automatic constraint rollback failed - manual intervention required"
            ROLLBACK_SUCCESS=false
            return 1
        fi
    else
        log_error "Use --force for automatic rollback or follow manual steps"
        ROLLBACK_SUCCESS=false
        return 1
    fi
}

# Rollback table
rollback_table() {
    local obj_name="${SCHEMA_NAME}.${OBJECT_NAME}"

    log_section "ROLLING BACK TABLE: ${obj_name}"

    log_error "Table rollback is NOT SUPPORTED automatically"
    log_warning "Tables require MANUAL RECOVERY due to data complexity"
    log_info ""
    log_info "Manual Table Rollback Procedure:"
    log_info "  1. Backup current data: pg_dump -t ${obj_name} > current_data.sql"
    log_info "  2. Drop table: DROP TABLE ${obj_name} CASCADE;"
    log_info "  3. Recreate from backup: psql -f ${BACKUP_FILE}"
    log_info "  4. Restore data (if needed): psql -f current_data.sql"
    log_info ""
    log_info "Considerations:"
    log_info "  - Foreign key dependencies (CASCADE will drop dependent objects)"
    log_info "  - Data loss (current data will be lost unless backed up)"
    log_info "  - Application downtime (table unavailable during rollback)"
    log_info "  - Index recreation (indexes must be recreated)"
    log_info "  - Constraint recreation (constraints must be recreated)"
    log_info ""
    log_info "Backup file: ${BACKUP_FILE}"

    ROLLBACK_SUCCESS=false
    return 1
}

# Validate rollback
validate_rollback() {
    local obj_type="$1"
    local obj_name="${SCHEMA_NAME}.${OBJECT_NAME}"

    if [[ "${SKIP_VALIDATION}" == "true" ]]; then
        log_warning "Validation skipped (--skip-validation)"
        return 0
    fi

    if [[ "${EMERGENCY_MODE}" == "true" ]]; then
        log_emergency "Validation skipped (emergency mode)"
        return 0
    fi

    log_section "POST-ROLLBACK VALIDATION"

    case "${obj_type}" in
        procedure|function)
            # Check if procedure/function exists
            local exists=$(run_psql -t -c \
                "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid \
                 WHERE n.nspname = '${SCHEMA_NAME}' AND p.proname = '${OBJECT_NAME}';" \
                2>/dev/null | xargs || echo "0")

            if [[ "${exists}" -gt 0 ]]; then
                log_success "${obj_type^} exists after rollback"

                # Try to call with NULL parameters (basic smoke test)
                log_info "Attempting basic smoke test..."
                if run_psql -c "SELECT ${obj_name}();" > /dev/null 2>&1 || \
                   run_psql -c "SELECT * FROM ${obj_name}();" > /dev/null 2>&1; then
                    log_success "Smoke test passed"
                else
                    log_warning "Smoke test failed (may require parameters)"
                fi
                return 0
            else
                log_error "${obj_type^} does not exist after rollback"
                return 1
            fi
            ;;
        view)
            # Check if view exists
            local exists=$(run_psql -t -c \
                "SELECT COUNT(*) FROM pg_views WHERE schemaname = '${SCHEMA_NAME}' AND viewname = '${OBJECT_NAME}';" \
                2>/dev/null | xargs || echo "0")

            local mat_exists=$(run_psql -t -c \
                "SELECT COUNT(*) FROM pg_matviews WHERE schemaname = '${SCHEMA_NAME}' AND matviewname = '${OBJECT_NAME}';" \
                2>/dev/null | xargs || echo "0")

            if [[ "${exists}" -gt 0 || "${mat_exists}" -gt 0 ]]; then
                log_success "View exists after rollback"

                # Try to select from view
                log_info "Attempting query test..."
                if run_psql -c "SELECT * FROM ${obj_name} LIMIT 1;" > /dev/null 2>&1; then
                    log_success "Query test passed"
                else
                    log_warning "Query test failed"
                fi
                return 0
            else
                log_error "View does not exist after rollback"
                return 1
            fi
            ;;
        index)
            # Check if index exists
            local exists=$(run_psql -t -c \
                "SELECT COUNT(*) FROM pg_indexes WHERE schemaname = '${SCHEMA_NAME}' AND indexname = '${OBJECT_NAME}';" \
                2>/dev/null | xargs || echo "0")

            if [[ "${exists}" -gt 0 ]]; then
                log_success "Index exists after rollback"
                return 0
            else
                log_error "Index does not exist after rollback"
                return 1
            fi
            ;;
        constraint|table)
            log_warning "Validation not supported for ${obj_type}"
            return 0
            ;;
    esac
}

# Generate rollback report
generate_report() {
    local obj_type="$1"
    local obj_name="${SCHEMA_NAME}.${OBJECT_NAME}"
    local env="$3"

    log_section "ROLLBACK SUMMARY"

    echo "" | tee -a "${LOG_FILE}"
    echo -e "  Object Type:        ${obj_type}" | tee -a "${LOG_FILE}"
    echo -e "  Object Name:        ${obj_name}" | tee -a "${LOG_FILE}"
    echo -e "  Environment:        ${env} (${DB_NAME})" | tee -a "${LOG_FILE}"
    echo -e "  Backup File:        ${BACKUP_FILE}" | tee -a "${LOG_FILE}"
    echo -e "  Timestamp:          $(date '+%Y-%m-%d %H:%M:%S %Z')" | tee -a "${LOG_FILE}"
    echo -e "  User:               ${USER}" | tee -a "${LOG_FILE}"
    echo -e "  Emergency Mode:     ${EMERGENCY_MODE}" | tee -a "${LOG_FILE}"
    echo -e "  Force Mode:         ${FORCE_MODE}" | tee -a "${LOG_FILE}"
    echo -e "  Skip Validation:    ${SKIP_VALIDATION}" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"

    if [[ "${ROLLBACK_SUCCESS}" == "true" ]]; then
        log_success "ROLLBACK SUCCESSFUL"
        echo "" | tee -a "${LOG_FILE}"
        log_info "Log file: ${LOG_FILE}"
        return 0
    else
        log_error "ROLLBACK FAILED"
        echo "" | tee -a "${LOG_FILE}"
        log_info "Log file: ${LOG_FILE}"
        return 1
    fi
}

# Main execution
main() {
    # Initialize logging
    init_logging

    # Parse arguments
    if [[ $# -lt 2 ]]; then
        log_error "Insufficient arguments"
        echo ""
        show_usage
        exit 2
    fi

    # Parse object type and name
    OBJECT_TYPE="$1"
    FULL_OBJECT_NAME="$2"
    ENVIRONMENT="${3:-${DEFAULT_ENVIRONMENT}}"

    # Set database name based on environment
    case "${ENVIRONMENT}" in
        dev)
            DB_NAME="perseus_dev"
            ;;
        qa)
            DB_NAME="perseus_qa"
            ;;
        staging)
            DB_NAME="perseus_staging"
            ;;
        prod)
            DB_NAME="perseus_prod"
            ;;
        *)
            log_error "Invalid environment: ${ENVIRONMENT}"
            log_info "Supported: dev, qa, staging, prod"
            exit 2
            ;;
    esac

    # Parse options
    shift 2
    if [[ $# -gt 0 ]]; then
        shift  # Skip environment if provided
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_usage
                exit 0
                ;;
            --emergency)
                EMERGENCY_MODE=true
                SKIP_VALIDATION=true
                log_emergency "Emergency mode enabled"
                shift
                ;;
            --force)
                FORCE_MODE=true
                log_warning "Force mode enabled"
                shift
                ;;
            --skip-validation)
                SKIP_VALIDATION=true
                log_warning "Validation will be skipped"
                shift
                ;;
            --backup-file)
                if [[ $# -lt 2 ]]; then
                    log_error "--backup-file requires a file path"
                    exit 2
                fi
                EXPLICIT_BACKUP_FILE="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 2
                ;;
        esac
    done

    # Validate object type
    if ! validate_object_type "${OBJECT_TYPE}"; then
        exit 2
    fi

    # Parse object name
    parse_object_name "${FULL_OBJECT_NAME}"

    # Detect execution mode
    detect_execution_mode

    # Load password
    load_password

    # Check database connection
    check_database

    # Find backup file
    if ! find_backup_file "${OBJECT_TYPE}" "${OBJECT_NAME}"; then
        log_error "Cannot proceed without backup file"
        exit 2
    fi

    # Confirm rollback
    confirm_rollback "${OBJECT_TYPE}" "${FULL_OBJECT_NAME}" "${ENVIRONMENT}"

    # Execute rollback based on object type
    case "${OBJECT_TYPE}" in
        procedure)
            rollback_procedure_or_function "procedure" || exit 1
            ;;
        function)
            rollback_procedure_or_function "function" || exit 1
            ;;
        view)
            rollback_view || exit 1
            ;;
        index)
            rollback_index || exit 1
            ;;
        constraint)
            rollback_constraint || exit 1
            ;;
        table)
            rollback_table || exit 1
            ;;
    esac

    # Validate rollback
    if ! validate_rollback "${OBJECT_TYPE}"; then
        log_error "Post-rollback validation failed"
        generate_report "${OBJECT_TYPE}" "${FULL_OBJECT_NAME}" "${ENVIRONMENT}"
        exit 3
    fi

    # Generate report
    if generate_report "${OBJECT_TYPE}" "${FULL_OBJECT_NAME}" "${ENVIRONMENT}"; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
