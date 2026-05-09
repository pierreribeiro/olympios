#!/usr/bin/env bash
#
# Perseus Database Migration - Object Deployment Script
#
# This script deploys individual database objects (procedures, functions, views,
# tables, indexes, constraints) with comprehensive validation, backup, and rollback
# capabilities.
#
# Usage:
#   ./deploy-object.sh <object_type> <sql_file_path> [options]
#
# Arguments:
#   object_type       Type of database object (procedure|function|view|table|index|constraint)
#   sql_file_path     Path to SQL file containing object definition
#
# Options:
#   --env <env>       Environment (dev|staging|prod) [default: dev]
#   --skip-backup     Skip backup creation (NOT RECOMMENDED)
#   --skip-syntax     Skip syntax validation
#   --skip-deps       Skip dependency validation
#   --force           Force deployment even if warnings detected
#   --dry-run         Validate only, do not deploy
#   --help            Show this help message
#
# Environment Variables:
#   DB_USER           Database user (default: perseus_admin)
#   DB_NAME           Database name (default: perseus_dev)
#   DB_HOST           Database host (default: localhost)
#   DB_PORT           Database port (default: 5432)
#   PGPASSWORD_FILE   Password file path
#   DOCKER_CONTAINER  Docker container name (default: perseus-postgres-dev)
#
# Exit Codes:
#   0 - Deployment successful
#   1 - Validation failed (pre-deployment)
#   2 - Deployment failed (with rollback)
#   3 - Rollback failed (CRITICAL)
#   4 - Invalid arguments or configuration
#
# Examples:
#   # Deploy a procedure
#   ./deploy-object.sh procedure source/building/pgsql/refactored/20.\ create-procedure/1.\ perseus.getmaterialbyrunproperties.sql
#
#   # Deploy to staging
#   ./deploy-object.sh --env staging view source/building/pgsql/refactored/15.\ create-view/translated.sql
#
#   # Dry-run deployment
#   ./deploy-object.sh --dry-run function source/building/pgsql/refactored/19.\ create-function/mcgetupstream.sql
#
# Features:
#   - Pre-deployment validation (syntax, dependencies)
#   - Automatic backup before replacement (7-day retention)
#   - Transaction-based deployment with automatic rollback on error
#   - Post-deployment verification
#   - Migration log tracking (perseus.migration_log)
#   - Comprehensive error handling and logging
#   - Docker/native PostgreSQL support
#
# Author: Perseus Migration Team
# Created: 2026-01-25
# Version: 1.0.0
# Constitutional Compliance: Articles I-VII (POSIX, error handling, transactions)
#

# Future Enhancements Backlog Section
# 1. Create an env.conf or .json file for setting up script initial variables
# 2. Password are read from secrets file path at configuration file
# 3. Execution logs must be written in the global temporary directory informed in configuration file.
# 4. Directory logs tree pattern: {global_dir}/{branch_name}/{dir_script_souce}/file_name_{timestamp}.log
# 5. Need to check the repetition of the bug showed at file deploy-batch.sh
# 6. Review the entire scipt looking for bug or flaws in the execution logic, explore edge cases


set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VALIDATION_SCRIPTS="${PROJECT_ROOT}/scripts/validation"

# Database connection parameters
DB_USER="${DB_USER:-perseus_admin}"
DB_NAME="${DB_NAME:-perseus_dev}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
PGPASSWORD_FILE="${PGPASSWORD_FILE:-${PROJECT_ROOT}/infra/database/.secrets/postgres_password.txt}"
DOCKER_CONTAINER="${DOCKER_CONTAINER:-perseus-postgres-dev}"

# Deployment environment
DEPLOY_ENV="${ENV:-dev}"

# Backup configuration
BACKUP_DIR="${SCRIPT_DIR}/backups"
BACKUP_RETENTION_DAYS=7

# Execution mode (auto-detected)
USE_DOCKER=false

# Feature flags (command-line options)
SKIP_BACKUP=false
SKIP_SYNTAX=false
SKIP_DEPS=false
FORCE_DEPLOY=false
DRY_RUN=false

# Object metadata
OBJECT_TYPE=""
SQL_FILE_PATH=""
OBJECT_NAME=""
OBJECT_SCHEMA=""

# Logging
LOG_FILE=""
BACKUP_FILE=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    [[ -n "${LOG_FILE}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[✓ SUCCESS]${NC} $1"
    [[ -n "${LOG_FILE}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[✗ ERROR]${NC} $1" >&2
    [[ -n "${LOG_FILE}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}[⚠ WARNING]${NC} $1"
    [[ -n "${LOG_FILE}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $1" >> "${LOG_FILE}"
}

log_section() {
    echo ""
    echo -e "${CYAN}=========================================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}=========================================================================${NC}"
    [[ -n "${LOG_FILE}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] $1" >> "${LOG_FILE}"
}

log_step() {
    echo ""
    echo -e "${MAGENTA}>>> $1${NC}"
    [[ -n "${LOG_FILE}" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [STEP] $1" >> "${LOG_FILE}"
}

# =============================================================================
# HELP FUNCTION
# =============================================================================

show_usage() {
    cat << 'EOF'
Perseus Database Migration - Object Deployment Script

Usage:
  ./deploy-object.sh <object_type> <sql_file_path> [options]

Arguments:
  object_type       Type of database object:
                    - procedure (stored procedures)
                    - function (table-valued or scalar functions)
                    - view (standard or materialized views)
                    - table (base tables)
                    - index (indexes)
                    - constraint (PK, FK, unique, check constraints)

  sql_file_path     Absolute or relative path to SQL file

Options:
  --env <env>       Deployment environment: dev|staging|prod (default: dev)
  --skip-backup     Skip backup creation (NOT RECOMMENDED for production)
  --skip-syntax     Skip syntax validation (NOT RECOMMENDED)
  --skip-deps       Skip dependency validation
  --force           Force deployment even if warnings detected
  --dry-run         Validate only, do not execute deployment
  --help, -h        Show this help message

Environment Variables:
  DB_USER           Database user (default: perseus_admin)
  DB_NAME           Database name (default: perseus_dev)
  DB_HOST           Database host (default: localhost)
  DB_PORT           Database port (default: 5432)
  PGPASSWORD_FILE   Path to password file
  DOCKER_CONTAINER  Docker container name (default: perseus-postgres-dev)

Exit Codes:
  0 - Deployment successful
  1 - Validation failed
  2 - Deployment failed (with rollback)
  3 - Rollback failed (CRITICAL)
  4 - Invalid arguments

Examples:
  # Deploy a procedure to development
  ./deploy-object.sh procedure source/building/pgsql/refactored/20.\ create-procedure/1.\ perseus.getmaterialbyrunproperties.sql

  # Deploy a view to staging with dry-run
  ./deploy-object.sh --env staging --dry-run view source/building/pgsql/refactored/15.\ create-view/translated.sql

  # Force deploy a function (skip warnings)
  ./deploy-object.sh --force function source/building/pgsql/refactored/19.\ create-function/mcgetupstream.sql

For more information, see: scripts/deployment/README.md
EOF
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Detect execution mode (Docker vs native psql)
detect_execution_mode() {
    if command -v psql > /dev/null 2>&1; then
        USE_DOCKER=false
        log_info "Execution mode: Local psql client"
    elif command -v docker > /dev/null 2>&1; then
        if docker ps --filter "name=${DOCKER_CONTAINER}" --format "{{.Names}}" | grep -q "${DOCKER_CONTAINER}"; then
            USE_DOCKER=true
            log_info "Execution mode: Docker container (${DOCKER_CONTAINER})"
        else
            log_error "PostgreSQL container not running: ${DOCKER_CONTAINER}"
            log_info "Start container: cd ${PROJECT_ROOT}/infra/database && ./init-db.sh start"
            exit 4
        fi
    else
        log_error "Neither psql nor Docker is available"
        log_info "Install PostgreSQL client or ensure Docker is running"
        exit 4
    fi
}

# Execute psql command (local or Docker)
run_psql() {
    if [[ "${USE_DOCKER}" == "true" ]]; then
        docker exec -i "${DOCKER_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" "$@"
    else
        # Use PGPASSFILE instead of PGPASSWORD for better security
        # PGPASSFILE prevents password from appearing in process list
        local temp_pgpass=$(mktemp)
        trap "rm -f ${temp_pgpass}" RETURN

        # Create .pgpass format: hostname:port:database:username:password
        echo "${DB_HOST}:${DB_PORT}:${DB_NAME}:${DB_USER}:$(cat "${PGPASSWORD_FILE}")" > "${temp_pgpass}"
        chmod 600 "${temp_pgpass}"

        export PGPASSFILE="${temp_pgpass}"
        psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" "$@"
        unset PGPASSFILE
    fi
}

# Load database password (only for local mode)
load_password() {
    if [[ "${USE_DOCKER}" == "false" ]]; then
        if [[ ! -f "${PGPASSWORD_FILE}" ]]; then
            log_error "Password file not found: ${PGPASSWORD_FILE}"
            log_info "Run: cd ${PROJECT_ROOT}/infra/database && ./init-db.sh setup"
            exit 4
        fi
        export PGPASSWORD=$(cat "${PGPASSWORD_FILE}")
    fi
}

# Check database connection
check_database() {
    log_step "Checking database connection"

    if ! run_psql -c "SELECT version();" > /dev/null 2>&1; then
        log_error "Cannot connect to database: ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
        log_info "Ensure PostgreSQL is running and credentials are correct"
        exit 4
    fi

    log_success "Database connection OK: ${DB_NAME}"
}

# Extract object name and schema from SQL file
extract_object_metadata() {
    log_step "Extracting object metadata from SQL file"

    local sql_content
    sql_content=$(cat "${SQL_FILE_PATH}")

    # Try to extract schema.object_name from CREATE statements
    # Patterns: CREATE [OR REPLACE] {PROCEDURE|FUNCTION|VIEW|TABLE|INDEX} schema.name
    local pattern=""

    case "${OBJECT_TYPE}" in
        procedure)
            pattern='CREATE[[:space:]]+(?:OR[[:space:]]+REPLACE[[:space:]]+)?PROCEDURE[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\\.([a-zA-Z_][a-zA-Z0-9_]*)'
            ;;
        function)
            pattern='CREATE[[:space:]]+(?:OR[[:space:]]+REPLACE[[:space:]]+)?FUNCTION[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\\.([a-zA-Z_][a-zA-Z0-9_]*)'
            ;;
        view)
            pattern='CREATE[[:space:]]+(?:OR[[:space:]]+REPLACE[[:space:]]+)?(?:MATERIALIZED[[:space:]]+)?VIEW[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\\.([a-zA-Z_][a-zA-Z0-9_]*)'
            ;;
        table)
            pattern='CREATE[[:space:]]+TABLE[[:space:]]+(?:IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?([a-zA-Z_][a-zA-Z0-9_]*)\\.([a-zA-Z_][a-zA-Z0-9_]*)'
            ;;
        index)
            pattern='CREATE[[:space:]]+(?:UNIQUE[[:space:]]+)?INDEX[[:space:]]+(?:[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]+)?ON[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\\.([a-zA-Z_][a-zA-Z0-9_]*)'
            ;;
        constraint)
            pattern='ALTER[[:space:]]+TABLE[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)\\.([a-zA-Z_][a-zA-Z0-9_]*)'
            ;;
    esac

    # Use grep with Perl regex to extract schema and object name
    if echo "${sql_content}" | grep -iPoE "${pattern}" > /dev/null 2>&1; then
        OBJECT_SCHEMA=$(echo "${sql_content}" | grep -iPoE "${pattern}" | head -1 | grep -oP '(?<=\s)[a-zA-Z_][a-zA-Z0-9_]*(?=\.)' | head -1)
        OBJECT_NAME=$(echo "${sql_content}" | grep -iPoE "${pattern}" | head -1 | grep -oP '(?<=\.)[a-zA-Z_][a-zA-Z0-9_]*' | head -1)
    fi

    # Fallback: try simpler pattern without schema
    if [[ -z "${OBJECT_NAME}" ]]; then
        log_warning "Could not extract schema-qualified name, attempting fallback"
        OBJECT_SCHEMA="public"
        # Try to extract just the object name
        OBJECT_NAME=$(echo "${sql_content}" | grep -iPoE "(?:CREATE|ALTER)[[:space:]]+(?:OR[[:space:]]+REPLACE[[:space:]]+)?(?:PROCEDURE|FUNCTION|VIEW|TABLE|INDEX)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)" | head -1 | awk '{print $NF}')
    fi

    if [[ -z "${OBJECT_NAME}" ]]; then
        log_error "Could not extract object name from SQL file"
        log_info "Ensure the SQL file contains a valid CREATE/ALTER statement"
        exit 4
    fi

    log_success "Detected object: ${OBJECT_SCHEMA}.${OBJECT_NAME} (${OBJECT_TYPE})"
}

# Create backup directory structure
create_backup_dir() {
    local backup_date
    backup_date=$(date '+%Y-%m-%d')

    local daily_backup_dir="${BACKUP_DIR}/${backup_date}"

    if [[ ! -d "${daily_backup_dir}" ]]; then
        mkdir -p "${daily_backup_dir}"
        log_info "Created backup directory: ${daily_backup_dir}"
    fi

    echo "${daily_backup_dir}"
}

# Clean old backups (7-day retention)
cleanup_old_backups() {
    log_step "Cleaning old backups (retention: ${BACKUP_RETENTION_DAYS} days)"

    if [[ ! -d "${BACKUP_DIR}" ]]; then
        log_info "No backup directory exists, skipping cleanup"
        return 0
    fi

    # Find and remove backup directories older than retention period
    find "${BACKUP_DIR}" -maxdepth 1 -type d -mtime "+${BACKUP_RETENTION_DAYS}" -exec rm -rf {} \; 2>/dev/null || true

    log_success "Old backups cleaned up"
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Validate command-line arguments
validate_arguments() {
    log_step "Validating arguments"

    # Check object type
    case "${OBJECT_TYPE}" in
        procedure|function|view|table|index|constraint)
            log_success "Valid object type: ${OBJECT_TYPE}"
            ;;
        *)
            log_error "Invalid object type: ${OBJECT_TYPE}"
            log_info "Valid types: procedure, function, view, table, index, constraint"
            exit 4
            ;;
    esac

    # Check SQL file exists
    if [[ ! -f "${SQL_FILE_PATH}" ]]; then
        log_error "SQL file not found: ${SQL_FILE_PATH}"
        exit 4
    fi

    log_success "SQL file exists: ${SQL_FILE_PATH}"

    # Check environment
    case "${DEPLOY_ENV}" in
        dev|staging|prod)
            log_success "Deployment environment: ${DEPLOY_ENV}"
            ;;
        *)
            log_error "Invalid environment: ${DEPLOY_ENV}"
            log_info "Valid environments: dev, staging, prod"
            exit 4
            ;;
    esac
}

# Run syntax validation
validate_syntax() {
    if [[ "${SKIP_SYNTAX}" == "true" ]]; then
        log_warning "Skipping syntax validation (--skip-syntax flag)"
        return 0
    fi

    log_step "Running syntax validation"

    local syntax_script="${VALIDATION_SCRIPTS}/syntax-check.sh"

    if [[ ! -x "${syntax_script}" ]]; then
        log_warning "Syntax check script not found or not executable: ${syntax_script}"
        return 0
    fi

    if "${syntax_script}" "${SQL_FILE_PATH}" > /dev/null 2>&1; then
        log_success "Syntax validation passed"
        return 0
    else
        log_error "Syntax validation failed"
        log_info "Run manually: ${syntax_script} ${SQL_FILE_PATH}"
        return 1
    fi
}

# Run dependency validation
validate_dependencies() {
    if [[ "${SKIP_DEPS}" == "true" ]]; then
        log_warning "Skipping dependency validation (--skip-deps flag)"
        return 0
    fi

    log_step "Running dependency validation"

    local dep_script="${VALIDATION_SCRIPTS}/dependency-check.sql"

    if [[ ! -f "${dep_script}" ]]; then
        log_warning "Dependency check script not found: ${dep_script}"
        return 0
    fi

    # For now, just log that we would run it
    # Full dependency validation is complex and may require object-specific checks
    log_info "Dependency check available but skipped (run manually if needed)"
    log_info "Manual check: psql -d ${DB_NAME} -f ${dep_script}"

    return 0
}

# =============================================================================
# BACKUP FUNCTIONS
# =============================================================================

# Backup existing object
backup_object() {
    if [[ "${SKIP_BACKUP}" == "true" ]]; then
        log_warning "Skipping backup creation (--skip-backup flag)"
        return 0
    fi

    log_step "Creating backup of existing object (if exists)"

    # Create backup directory
    local daily_backup_dir
    daily_backup_dir=$(create_backup_dir)

    # Generate backup filename
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    BACKUP_FILE="${daily_backup_dir}/${OBJECT_TYPE}_${OBJECT_SCHEMA}_${OBJECT_NAME}_${timestamp}.sql"

    # Check if object exists and create backup
    local object_exists=false
    local backup_sql=""

    case "${OBJECT_TYPE}" in
        procedure)
            if run_psql -c "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = '${OBJECT_SCHEMA}' AND p.proname = '${OBJECT_NAME}' AND p.prokind = 'p';" -t | grep -q 1; then
                object_exists=true
                backup_sql="SELECT pg_get_functiondef(p.oid) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = '${OBJECT_SCHEMA}' AND p.proname = '${OBJECT_NAME}' AND p.prokind = 'p';"
            fi
            ;;
        function)
            if run_psql -c "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = '${OBJECT_SCHEMA}' AND p.proname = '${OBJECT_NAME}' AND p.prokind = 'f';" -t | grep -q 1; then
                object_exists=true
                backup_sql="SELECT pg_get_functiondef(p.oid) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = '${OBJECT_SCHEMA}' AND p.proname = '${OBJECT_NAME}' AND p.prokind = 'f';"
            fi
            ;;
        view)
            if run_psql -c "SELECT 1 FROM pg_views WHERE schemaname = '${OBJECT_SCHEMA}' AND viewname = '${OBJECT_NAME}';" -t | grep -q 1; then
                object_exists=true
                backup_sql="SELECT 'CREATE OR REPLACE VIEW ${OBJECT_SCHEMA}.${OBJECT_NAME} AS ' || definition FROM pg_views WHERE schemaname = '${OBJECT_SCHEMA}' AND viewname = '${OBJECT_NAME}';"
            fi
            ;;
        table)
            if run_psql -c "SELECT 1 FROM pg_tables WHERE schemaname = '${OBJECT_SCHEMA}' AND tablename = '${OBJECT_NAME}';" -t | grep -q 1; then
                object_exists=true
                # For tables, we use pg_dump for complete backup
                if [[ "${USE_DOCKER}" == "true" ]]; then
                    docker exec -i "${DOCKER_CONTAINER}" pg_dump -U "${DB_USER}" -d "${DB_NAME}" -t "${OBJECT_SCHEMA}.${OBJECT_NAME}" --schema-only > "${BACKUP_FILE}"
                else
                    PGPASSWORD=$(cat "${PGPASSWORD_FILE}") pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t "${OBJECT_SCHEMA}.${OBJECT_NAME}" --schema-only > "${BACKUP_FILE}"
                fi
            fi
            ;;
        index|constraint)
            # For indexes and constraints, we don't need full backups as they can be recreated
            log_info "Indexes and constraints don't require backup (can be recreated)"
            return 0
            ;;
    esac

    if [[ "${object_exists}" == "true" ]]; then
        # Create backup file header
        cat > "${BACKUP_FILE}" << EOF
-- ============================================================================
-- BACKUP: ${OBJECT_SCHEMA}.${OBJECT_NAME} (${OBJECT_TYPE})
-- ============================================================================
-- Backup Date: $(date '+%Y-%m-%d %H:%M:%S')
-- Environment: ${DEPLOY_ENV}
-- Database: ${DB_NAME}
-- Original File: ${SQL_FILE_PATH}
--
-- This is an automatic backup created before deployment.
-- Retention: ${BACKUP_RETENTION_DAYS} days
-- ============================================================================

EOF

        # Append object definition (if not already done by pg_dump)
        if [[ "${OBJECT_TYPE}" != "table" ]] && [[ -n "${backup_sql}" ]]; then
            run_psql -c "${backup_sql}" -t >> "${BACKUP_FILE}"
        fi

        log_success "Backup created: ${BACKUP_FILE}"
    else
        log_info "Object does not exist (new object, no backup needed)"
        BACKUP_FILE=""
    fi

    # Cleanup old backups
    cleanup_old_backups
}

# =============================================================================
# DEPLOYMENT FUNCTIONS
# =============================================================================

# Deploy object to database
deploy_object() {
    log_step "Deploying object to database"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warning "DRY RUN MODE - Deployment skipped"
        return 0
    fi

    # Create transaction wrapper
    local temp_file=$(mktemp)
    trap "rm -f ${temp_file}" RETURN

    cat > "${temp_file}" << 'EOF'
-- ============================================================================
-- DEPLOYMENT TRANSACTION (AUTO-ROLLBACK ON ERROR)
-- ============================================================================
BEGIN;

-- Set error handling to stop on first error
\set ON_ERROR_STOP on
\set ON_ERROR_ROLLBACK on

EOF

    # Append SQL file content
    cat "${SQL_FILE_PATH}" >> "${temp_file}"

    # Append commit
    cat >> "${temp_file}" << 'EOF'

-- Commit transaction
COMMIT;
EOF

    # Execute deployment
    local error_output=$(mktemp)
    trap "rm -f ${error_output}" RETURN

    local deployment_success=false

    if [[ "${USE_DOCKER}" == "true" ]]; then
        # Copy file to container
        local container_temp="/tmp/deploy_$(basename ${temp_file})"
        docker cp "${temp_file}" "${DOCKER_CONTAINER}:${container_temp}" 2>/dev/null

        if docker exec -i "${DOCKER_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" -f "${container_temp}" > /dev/null 2> "${error_output}"; then
            deployment_success=true
        fi

        docker exec "${DOCKER_CONTAINER}" rm -f "${container_temp}" 2>/dev/null || true
    else
        if run_psql -f "${temp_file}" > /dev/null 2> "${error_output}"; then
            deployment_success=true
        fi
    fi

    if [[ "${deployment_success}" == "true" ]]; then
        log_success "Object deployed successfully: ${OBJECT_SCHEMA}.${OBJECT_NAME}"
        return 0
    else
        log_error "Deployment failed with errors:"
        echo ""
        sed 's/^/    /' "${error_output}"
        echo ""

        # If backup exists, offer to rollback
        if [[ -n "${BACKUP_FILE}" ]] && [[ -f "${BACKUP_FILE}" ]]; then
            log_warning "Backup available for rollback: ${BACKUP_FILE}"
            log_info "To rollback: ${SCRIPT_DIR}/rollback-object.sh ${BACKUP_FILE}"
        fi

        return 2
    fi
}

# Verify deployment
verify_deployment() {
    log_step "Verifying deployment"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "DRY RUN MODE - Verification skipped"
        return 0
    fi

    local object_exists=false

    case "${OBJECT_TYPE}" in
        procedure)
            if run_psql -c "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = '${OBJECT_SCHEMA}' AND p.proname = '${OBJECT_NAME}' AND p.prokind = 'p';" -t | grep -q 1; then
                object_exists=true
            fi
            ;;
        function)
            if run_psql -c "SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = '${OBJECT_SCHEMA}' AND p.proname = '${OBJECT_NAME}' AND p.prokind = 'f';" -t | grep -q 1; then
                object_exists=true
            fi
            ;;
        view)
            if run_psql -c "SELECT 1 FROM pg_views WHERE schemaname = '${OBJECT_SCHEMA}' AND viewname = '${OBJECT_NAME}';" -t | grep -q 1; then
                object_exists=true
            elif run_psql -c "SELECT 1 FROM pg_matviews WHERE schemaname = '${OBJECT_SCHEMA}' AND matviewname = '${OBJECT_NAME}';" -t | grep -q 1; then
                object_exists=true
            fi
            ;;
        table)
            if run_psql -c "SELECT 1 FROM pg_tables WHERE schemaname = '${OBJECT_SCHEMA}' AND tablename = '${OBJECT_NAME}';" -t | grep -q 1; then
                object_exists=true
            fi
            ;;
        index)
            if run_psql -c "SELECT 1 FROM pg_indexes WHERE schemaname = '${OBJECT_SCHEMA}' AND indexname = '${OBJECT_NAME}';" -t | grep -q 1; then
                object_exists=true
            fi
            ;;
        constraint)
            if run_psql -c "SELECT 1 FROM information_schema.table_constraints WHERE constraint_schema = '${OBJECT_SCHEMA}' AND constraint_name = '${OBJECT_NAME}';" -t | grep -q 1; then
                object_exists=true
            fi
            ;;
    esac

    if [[ "${object_exists}" == "true" ]]; then
        log_success "Verification passed: Object exists in database"
        return 0
    else
        log_error "Verification failed: Object not found in database"
        return 1
    fi
}

# Update migration log
update_migration_log() {
    log_step "Updating migration log"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "DRY RUN MODE - Migration log update skipped"
        return 0
    fi

    # Create migration_log table if it doesn't exist
    local create_log_table="
CREATE TABLE IF NOT EXISTS perseus.migration_log (
    id SERIAL PRIMARY KEY,
    object_type VARCHAR(50) NOT NULL,
    object_schema VARCHAR(100) NOT NULL,
    object_name VARCHAR(200) NOT NULL,
    deployment_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deployment_environment VARCHAR(20) NOT NULL,
    deployment_user VARCHAR(100) NOT NULL,
    sql_file_path TEXT NOT NULL,
    backup_file_path TEXT,
    deployment_status VARCHAR(20) NOT NULL,
    error_message TEXT,
    deployment_duration_ms INTEGER
);
"

    run_psql -c "${create_log_table}" > /dev/null 2>&1 || true

    # Insert deployment record
    local insert_log="
INSERT INTO perseus.migration_log (
    object_type, object_schema, object_name,
    deployment_environment, deployment_user,
    sql_file_path, backup_file_path, deployment_status
) VALUES (
    '${OBJECT_TYPE}',
    '${OBJECT_SCHEMA}',
    '${OBJECT_NAME}',
    '${DEPLOY_ENV}',
    '${DB_USER}',
    '${SQL_FILE_PATH}',
    '${BACKUP_FILE}',
    'SUCCESS'
);
"

    if run_psql -c "${insert_log}" > /dev/null 2>&1; then
        log_success "Migration log updated"
    else
        log_warning "Could not update migration log (non-critical)"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Parse arguments (check for help first, before showing header)
    if [[ $# -eq 0 ]]; then
        log_section "PERSEUS DATABASE MIGRATION - OBJECT DEPLOYMENT"
        log_error "No arguments provided"
        echo ""
        show_usage
        exit 4
    fi

    # Check for help flag before showing header
    for arg in "$@"; do
        if [[ "$arg" == "--help" ]] || [[ "$arg" == "-h" ]]; then
            show_usage
            exit 0
        fi
    done

    log_section "PERSEUS DATABASE MIGRATION - OBJECT DEPLOYMENT"

    # Parse command line
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_usage
                exit 0
                ;;
            --env)
                DEPLOY_ENV="$2"
                shift 2
                ;;
            --skip-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --skip-syntax)
                SKIP_SYNTAX=true
                shift
                ;;
            --skip-deps)
                SKIP_DEPS=true
                shift
                ;;
            --force)
                FORCE_DEPLOY=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 4
                ;;
            *)
                if [[ -z "${OBJECT_TYPE}" ]]; then
                    OBJECT_TYPE="$1"
                elif [[ -z "${SQL_FILE_PATH}" ]]; then
                    SQL_FILE_PATH="$1"
                else
                    log_error "Too many arguments: $1"
                    exit 4
                fi
                shift
                ;;
        esac
    done

    # Check required arguments
    if [[ -z "${OBJECT_TYPE}" ]] || [[ -z "${SQL_FILE_PATH}" ]]; then
        log_error "Missing required arguments: object_type and sql_file_path"
        echo ""
        show_usage
        exit 4
    fi

    # Convert relative path to absolute
    if [[ "${SQL_FILE_PATH}" != /* ]]; then
        SQL_FILE_PATH="${PWD}/${SQL_FILE_PATH}"
    fi

    # Setup logging
    LOG_FILE="${SCRIPT_DIR}/deploy-$(date '+%Y%m%d_%H%M%S').log"
    log_info "Deployment log: ${LOG_FILE}"

    # Display deployment info
    echo ""
    log_info "Object Type:    ${OBJECT_TYPE}"
    log_info "SQL File:       ${SQL_FILE_PATH}"
    log_info "Environment:    ${DEPLOY_ENV}"
    log_info "Database:       ${DB_NAME}"
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warning "DRY RUN MODE ENABLED - No changes will be made"
    fi

    # Validate arguments
    validate_arguments

    # Detect execution mode and check database
    detect_execution_mode
    load_password
    check_database

    # Extract object metadata
    extract_object_metadata

    # Pre-deployment validation
    log_section "PRE-DEPLOYMENT VALIDATION"

    local validation_failed=false

    validate_syntax || validation_failed=true
    validate_dependencies || validation_failed=true

    if [[ "${validation_failed}" == "true" ]] && [[ "${FORCE_DEPLOY}" == "false" ]]; then
        log_error "Validation failed. Use --force to deploy anyway (NOT RECOMMENDED)"
        exit 1
    elif [[ "${validation_failed}" == "true" ]]; then
        log_warning "Validation failed but --force flag used, continuing deployment"
    fi

    # Backup
    log_section "BACKUP CREATION"
    backup_object

    # Deployment
    log_section "DEPLOYMENT EXECUTION"

    if deploy_object; then
        # Post-deployment verification
        log_section "POST-DEPLOYMENT VERIFICATION"

        if verify_deployment; then
            update_migration_log

            log_section "DEPLOYMENT SUMMARY"
            log_success "Deployment completed successfully!"
            echo ""
            log_info "Object:         ${OBJECT_SCHEMA}.${OBJECT_NAME}"
            log_info "Type:           ${OBJECT_TYPE}"
            log_info "Environment:    ${DEPLOY_ENV}"
            if [[ -n "${BACKUP_FILE}" ]]; then
                log_info "Backup:         ${BACKUP_FILE}"
            fi
            log_info "Log:            ${LOG_FILE}"
            echo ""

            exit 0
        else
            log_error "Post-deployment verification failed"
            exit 2
        fi
    else
        log_error "Deployment failed"
        exit 2
    fi
}

# Run main function
main "$@"
