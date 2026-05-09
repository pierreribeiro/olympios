#!/usr/bin/env bash
# =============================================================================
# Perseus Database Migration - Batch Deployment Script
# =============================================================================
# Purpose: Deploy multiple database objects in dependency-aware order with
#          validation, rollback capabilities, and comprehensive logging.
#
# Usage:
#   ./deploy-batch.sh <file1.sql> [file2.sql ...]
#   ./deploy-batch.sh --dir <directory>
#   ./deploy-batch.sh --list <file-list.txt>
#   ./deploy-batch.sh --all
#
# Options:
#   <files>           One or more SQL files to deploy
#   --dir <path>      Deploy all .sql files in directory (recursive)
#   --list <file>     Deploy files listed in text file (one per line)
#   --all             Deploy all SQL files in dependency order (0-21)
#   --continue        Continue on error (default: stop on first failure)
#   --skip-syntax     Skip syntax validation (not recommended)
#   --skip-deps       Skip dependency validation (not recommended)
#   --dry-run         Validate only, do not deploy
#   --help            Show this help message
#
# Exit Codes:
#   0 - All deployments succeeded
#   1 - One or more deployments failed
#   2 - Invalid arguments or missing prerequisites
#   3 - Database connection failed
#
# Examples:
#   # Deploy specific procedures
#   ./deploy-batch.sh sp_move_node.sql sp_add_arc.sql
#
#   # Deploy all procedures in directory
#   ./deploy-batch.sh --dir source/building/pgsql/refactored/20.\ create-procedure/
#
#   # Deploy from file list
#   cat > deploy-list.txt <<EOF
#   source/building/pgsql/refactored/14. create-table/goo.sql
#   source/building/pgsql/refactored/15. create-view/v_material.sql
#   EOF
#   ./deploy-batch.sh --list deploy-list.txt
#
#   # Dry run (validation only)
#   ./deploy-batch.sh --dry-run --all
#
# Author: Perseus Migration Team
# Constitution Compliance: Article VII (Modular Logic Separation)
# Last Updated: 2026-01-25
# =============================================================================


# Future Enhancements Backlog Section
# 1. Create an env.conf or .json file for setting up script initial variables
# 2. Password are read from secrets file path at configuration file
# 3. Execution logs must be written in the global temporary directory informed in configuration file.
# 4. Directory logs tree pattern: {global_dir}/{branch_name}/{dir_script_souce}/file_name_{timestamp}.log
# 5. There's a bug at line 311 'trap "rm -f ${temp_output}" RETURN'. In the execution flow, the log file is deleted before the message:
#    'log_warning "Dependency check found CRITICAL issues (review recommended)"' at line 316
# 6. Need to check the repetition of the explained bug above
# 7. Review the entire scipt looking for bug or flaws in the execution logic, explore edge cases

set -euo pipefail

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Database connection parameters
DB_USER="${DB_USER:-perseus_admin}"
DB_NAME="${DB_NAME:-perseus_dev}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
#PGPASSWORD_FILE="${PGPASSWORD_FILE:-${PROJECT_ROOT}/infra/database/.secrets/postgres_password.txt}"
PGPASSWORD_FILE="${PGPASSWORD_FILE:-/Users/pierre.ribeiro/workspace/sharing/sqlserver-to-postgresql-migration/perseus-database/.secrets/postgres_password.txt}"
DOCKER_CONTAINER="${DOCKER_CONTAINER:-perseus-postgres-dev}"

# Execution mode
USE_DOCKER=false

# Deployment options
CONTINUE_ON_ERROR=false
SKIP_SYNTAX_CHECK=false
SKIP_DEPENDENCY_CHECK=false
DRY_RUN=false

# Deployment tracking
TOTAL_FILES=0
DEPLOYED_FILES=0
FAILED_FILES=0
SKIPPED_FILES=0
declare -a FAILED_FILE_LIST=()
declare -a DEPLOYMENT_LOG=()

# Temporary directory for backups and logs
DEPLOY_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${PROJECT_ROOT}/.deploy-backups/${DEPLOY_TIMESTAMP}"
LOG_FILE="${BACKUP_DIR}/deployment.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# =============================================================================
# Logging Functions
# =============================================================================

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} ${message}"
    echo "[INFO] [$(date '+%Y-%m-%d %H:%M:%S')] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[✓ SUCCESS]${NC} ${message}"
    echo "[SUCCESS] [$(date '+%Y-%m-%d %H:%M:%S')] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
}

log_error() {
    local message="$1"
    echo -e "${RED}[✗ ERROR]${NC} ${message}" >&2
    echo "[ERROR] [$(date '+%Y-%m-%d %H:%M:%S')] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[⚠ WARNING]${NC} ${message}"
    echo "[WARNING] [$(date '+%Y-%m-%d %H:%M:%S')] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
}

log_section() {
    local message="$1"
    echo ""
    echo -e "${CYAN}=========================================================================${NC}"
    echo -e "${CYAN}${message}${NC}"
    echo -e "${CYAN}=========================================================================${NC}"
    echo ""
    echo "=========================================================================" >> "${LOG_FILE}" 2>/dev/null || true
    echo "${message}" >> "${LOG_FILE}" 2>/dev/null || true
    echo "=========================================================================" >> "${LOG_FILE}" 2>/dev/null || true
}

log_deploy() {
    local message="$1"
    echo -e "${MAGENTA}[DEPLOY]${NC} ${message}"
    echo "[DEPLOY] [$(date '+%Y-%m-%d %H:%M:%S')] ${message}" >> "${LOG_FILE}" 2>/dev/null || true
}

# =============================================================================
# Usage and Help
# =============================================================================

show_usage() {
    cat << 'EOF'
Perseus Database Migration - Batch Deployment Script

Usage:
  ./deploy-batch.sh <file1.sql> [file2.sql ...]
  ./deploy-batch.sh --dir <directory>
  ./deploy-batch.sh --list <file-list.txt>
  ./deploy-batch.sh --all
  ./deploy-batch.sh --help

Options:
  <files>           One or more SQL files to deploy
  --dir <path>      Deploy all .sql files in directory (recursive)
  --list <file>     Deploy files listed in text file (one per line)
  --all             Deploy all SQL files in dependency order (0-21)
  --continue        Continue on error (default: stop on first failure)
  --skip-syntax     Skip syntax validation (not recommended)
  --skip-deps       Skip dependency validation (not recommended)
  --dry-run         Validate only, do not deploy
  --help            Show this help message

Examples:
  # Deploy specific procedures
  ./deploy-batch.sh sp_move_node.sql sp_add_arc.sql

  # Deploy all procedures in directory
  ./deploy-batch.sh --dir source/building/pgsql/refactored/20.\ create-procedure/

  # Deploy from file list
  ./deploy-batch.sh --list deploy-list.txt

  # Dry run (validation only)
  ./deploy-batch.sh --dry-run --all

Environment Variables:
  DB_USER           Database user (default: perseus_admin)
  DB_NAME           Database name (default: perseus_dev)
  DB_HOST           Database host (default: localhost)
  DB_PORT           Database port (default: 5432)
  PGPASSWORD_FILE   Password file path
  DOCKER_CONTAINER  Docker container name (default: perseus-postgres-dev)

Exit Codes:
  0 - All deployments succeeded
  1 - One or more deployments failed
  2 - Invalid arguments or missing prerequisites
  3 - Database connection failed
EOF
}

# =============================================================================
# Database Connection Functions
# =============================================================================

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
            log_info "Start container: cd infra/database && ./init-db.sh start"
            exit 3
        fi
    else
        log_error "Neither psql nor Docker is available"
        log_info "Install PostgreSQL client: brew install postgresql@17"
        exit 3
    fi
}

run_psql() {
    if [[ "${USE_DOCKER}" == "true" ]]; then
        docker exec -i "${DOCKER_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" "$@"
    else
        export PGPASSWORD=$(cat "${PGPASSWORD_FILE}")
        psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" "$@"
    fi
}

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

check_database() {
    log_info "Checking database connection: ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

    if ! run_psql -c "SELECT version();" > /dev/null 2>&1; then
        log_error "Cannot connect to database"
        log_info "Ensure PostgreSQL is running: cd infra/database && ./init-db.sh start"
        exit 3
    fi

    local version=$(run_psql -t -c "SELECT version();" 2>/dev/null | head -n1 | xargs)
    log_success "Database connection OK: ${version}"
}

# =============================================================================
# Validation Functions
# =============================================================================

validate_syntax() {
    local file="$1"

    if [[ "${SKIP_SYNTAX_CHECK}" == "true" ]]; then
        log_warning "Syntax check skipped (not recommended)"
        return 0
    fi

    log_info "Running syntax validation: $(basename "${file}")"

    local syntax_script="${PROJECT_ROOT}/scripts/validation/syntax-check.sh"
    if [[ ! -f "${syntax_script}" ]]; then
        log_error "Syntax check script not found: ${syntax_script}"
        return 1
    fi

    if "${syntax_script}" "${file}" > /dev/null 2>&1; then
        log_success "Syntax validation passed"
        return 0
    else
        log_error "Syntax validation failed"
        return 1
    fi
}

check_dependencies() {
    if [[ "${SKIP_DEPENDENCY_CHECK}" == "true" ]]; then
        log_warning "Dependency check skipped (not recommended)"
        return 0
    fi

    log_info "Checking database dependencies"

    local dep_script="${PROJECT_ROOT}/scripts/validation/dependency-check.sql"
    if [[ ! -f "${dep_script}" ]]; then
        log_warning "Dependency check script not found: ${dep_script}"
        return 0
    fi

    # Run dependency check (looking for CRITICAL issues only)
    local temp_output=$(mktemp)
    #trap "rm -f ${temp_output}" RETURN

    if run_psql -f "${dep_script}" > "${temp_output}" 2>&1; then
        if grep -q "CRITICAL" "${temp_output}"; then
            log_warning "Dependency check found CRITICAL issues (review recommended)"
            log_info "See: ${temp_output}"
        else
            log_success "Dependency check passed"
        fi
        return 0
    else
        log_warning "Dependency check script failed (continuing anyway)"
        return 0
    fi
}

# =============================================================================
# Backup Functions
# =============================================================================

create_backup_object() {
    local file="$1"
    local object_name=$(basename "${file}" .sql)
    local backup_file="${BACKUP_DIR}/${object_name}_backup.sql"

    log_info "Creating backup: ${object_name}"

    # Extract object definition from database (if exists)
    local object_type=$(detect_object_type "${file}")

    case "${object_type}" in
        PROCEDURE|FUNCTION)
            local schema="public"
            run_psql -c "\\sf ${schema}.${object_name}" > "${backup_file}" 2>/dev/null || {
                log_info "Object does not exist yet (new deployment)"
                echo "-- No existing object to backup" > "${backup_file}"
                return 0
            }
            ;;
        VIEW)
            run_psql -c "\\d+ ${object_name}" > "${backup_file}" 2>/dev/null || {
                log_info "View does not exist yet (new deployment)"
                echo "-- No existing view to backup" > "${backup_file}"
                return 0
            }
            ;;
        TABLE)
            log_warning "Table backup not implemented (schema change detection only)"
            echo "-- Table structure backup not implemented" > "${backup_file}"
            return 0
            ;;
        *)
            log_warning "Unknown object type, skipping backup"
            echo "-- Unknown object type" > "${backup_file}"
            return 0
            ;;
    esac

    log_success "Backup created: ${backup_file}"
}

detect_object_type() {
    local file="$1"

    if grep -qi "CREATE OR REPLACE PROCEDURE" "${file}"; then
        echo "PROCEDURE"
    elif grep -qi "CREATE OR REPLACE FUNCTION" "${file}"; then
        echo "FUNCTION"
    elif grep -qi "CREATE.*VIEW" "${file}"; then
        echo "VIEW"
    elif grep -qi "CREATE TABLE" "${file}"; then
        echo "TABLE"
    elif grep -qi "CREATE INDEX" "${file}"; then
        echo "INDEX"
    elif grep -qi "ALTER TABLE.*ADD CONSTRAINT" "${file}"; then
        echo "CONSTRAINT"
    else
        echo "UNKNOWN"
    fi
}

# =============================================================================
# Deployment Functions
# =============================================================================

deploy_file() {
    local file="$1"
    local filename=$(basename "${file}")
    local object_name=$(basename "${file}" .sql)

    TOTAL_FILES=$((TOTAL_FILES + 1))

    log_section "DEPLOYING: ${filename} (${TOTAL_FILES}/${TOTAL_FILES})"

    # Validate file exists
    if [[ ! -f "${file}" ]]; then
        log_error "File not found: ${file}"
        FAILED_FILES=$((FAILED_FILES + 1))
        FAILED_FILE_LIST+=("${file} - File not found")
        return 1
    fi

    # Syntax validation
    if ! validate_syntax "${file}"; then
        log_error "Deployment aborted: Syntax validation failed"
        FAILED_FILES=$((FAILED_FILES + 1))
        FAILED_FILE_LIST+=("${file} - Syntax validation failed")
        return 1
    fi

    # Create backup
    if [[ "${DRY_RUN}" == "false" ]]; then
        create_backup_object "${file}" || {
            log_warning "Backup creation failed (continuing anyway)"
        }
    fi

    # Deploy (or dry run)
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "DRY RUN: Would deploy ${filename}"
        DEPLOYED_FILES=$((DEPLOYED_FILES + 1))
        DEPLOYMENT_LOG+=("DRY RUN: ${filename}")
        return 0
    fi

    # Execute deployment
    log_deploy "Executing: ${filename}"

    local error_output=$(mktemp)
    local start_time=$(date +%s)
    trap "rm -f ${error_output}" RETURN

    # For Docker mode, copy file to container
    if [[ "${USE_DOCKER}" == "true" ]]; then
        local container_temp="/tmp/deploy_$(basename ${file})"
        docker cp "${file}" "${DOCKER_CONTAINER}:${container_temp}" 2>/dev/null

        if docker exec -i "${DOCKER_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" \
             -f "${container_temp}" > /dev/null 2> "${error_output}"; then
            docker exec "${DOCKER_CONTAINER}" rm -f "${container_temp}" 2>/dev/null || true
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            log_success "Deployed successfully in ${duration}s"
            DEPLOYED_FILES=$((DEPLOYED_FILES + 1))
            DEPLOYMENT_LOG+=("SUCCESS: ${filename} (${duration}s)")
            return 0
        else
            docker exec "${DOCKER_CONTAINER}" rm -f "${container_temp}" 2>/dev/null || true
            log_error "Deployment failed:"
            echo ""
            sed 's/^/    /' "${error_output}"
            echo ""
            FAILED_FILES=$((FAILED_FILES + 1))
            FAILED_FILE_LIST+=("${file} - Deployment failed")
            DEPLOYMENT_LOG+=("FAILED: ${filename}")
            return 1
        fi
    else
        # Local psql execution
        if run_psql -f "${file}" > /dev/null 2> "${error_output}"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            log_success "Deployed successfully in ${duration}s"
            DEPLOYED_FILES=$((DEPLOYED_FILES + 1))
            DEPLOYMENT_LOG+=("SUCCESS: ${filename} (${duration}s)")
            return 0
        else
            log_error "Deployment failed:"
            echo ""
            sed 's/^/    /' "${error_output}"
            echo ""
            FAILED_FILES=$((FAILED_FILES + 1))
            FAILED_FILE_LIST+=("${file} - Deployment failed")
            DEPLOYMENT_LOG+=("FAILED: ${filename}")
            return 1
        fi
    fi
}

# =============================================================================
# File Collection Functions
# =============================================================================

collect_files_from_args() {
    local -n files_array=$1
    shift

    for arg in "$@"; do
        if [[ -f "${arg}" ]]; then
            files_array+=("${arg}")
        else
            log_error "File not found: ${arg}"
            exit 2
        fi
    done
}

collect_files_from_directory() {
    local -n files_array=$1
    local dir="$2"

    if [[ ! -d "${dir}" ]]; then
        log_error "Directory not found: ${dir}"
        exit 2
    fi

    log_info "Collecting SQL files from: ${dir}"

    while IFS= read -r -d '' file; do
        files_array+=("${file}")
    done < <(find "${dir}" -type f -name "*.sql" -print0 | sort -z)

    log_info "Found ${#files_array[@]} SQL file(s)"
}

collect_files_from_list() {
    local -n files_array=$1
    local list_file="$2"

    if [[ ! -f "${list_file}" ]]; then
        log_error "List file not found: ${list_file}"
        exit 2
    fi

    log_info "Reading file list from: ${list_file}"

    while IFS= read -r line || [[ -n "${line}" ]]; do
        # Skip empty lines and comments
        [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        line=$(echo "${line}" | xargs)

        if [[ -f "${line}" ]]; then
            files_array+=("${line}")
        else
            log_warning "File not found (skipping): ${line}"
        fi
    done < "${list_file}"

    log_info "Loaded ${#files_array[@]} file(s) from list"
}

collect_all_files_in_order() {
    local -n files_array=$1
    local refactored_dir="${PROJECT_ROOT}/source/building/pgsql/refactored"

    if [[ ! -d "${refactored_dir}" ]]; then
        log_error "Refactored directory not found: ${refactored_dir}"
        exit 2
    fi

    log_info "Collecting all SQL files in dependency order"

    # Deployment order (0-21 directories)
    local order_dirs=(
        "10. create-extension"
        "11. create-schema"
        "12. create-type"
        "13. create-domain"
        "14. create-table"
        "15. create-view"
        "16. create-index"
        "17. create-constraint-pk"
        "18. create-constraint-fk"
        "19. create-function"
        "20. create-procedure"
        "21. create-trigger"
    )

    for order_dir in "${order_dirs[@]}"; do
        local full_path="${refactored_dir}/${order_dir}"
        if [[ -d "${full_path}" ]]; then
            log_info "Processing: ${order_dir}"
            while IFS= read -r -d '' file; do
                files_array+=("${file}")
            done < <(find "${full_path}" -type f -name "*.sql" -print0 | sort -z)
        fi
    done

    log_info "Collected ${#files_array[@]} file(s) in dependency order"
}

# =============================================================================
# Summary and Reporting
# =============================================================================

print_deployment_summary() {
    log_section "DEPLOYMENT SUMMARY"

    echo ""
    echo "  Total Files:        ${TOTAL_FILES}"
    echo -e "  ${GREEN}✓ Deployed:${NC}         ${DEPLOYED_FILES}"
    echo -e "  ${RED}✗ Failed:${NC}           ${FAILED_FILES}"
    echo -e "  ${YELLOW}⊘ Skipped:${NC}          ${SKIPPED_FILES}"
    echo ""

    if [[ ${#DEPLOYMENT_LOG[@]} -gt 0 ]]; then
        echo "Deployment Details:"
        echo "-------------------"
        for entry in "${DEPLOYMENT_LOG[@]}"; do
            echo "  ${entry}"
        done
        echo ""
    fi

    if [[ ${#FAILED_FILE_LIST[@]} -gt 0 ]]; then
        echo -e "${RED}Failed Deployments:${NC}"
        echo "-------------------"
        for failed in "${FAILED_FILE_LIST[@]}"; do
            echo -e "  ${RED}✗${NC} ${failed}"
        done
        echo ""
    fi

    echo "Deployment Timestamp: ${DEPLOY_TIMESTAMP}"
    echo "Log File:             ${LOG_FILE}"
    echo "Backup Directory:     ${BACKUP_DIR}"
    echo ""

    if [[ ${FAILED_FILES} -eq 0 ]]; then
        log_success "ALL DEPLOYMENTS COMPLETED SUCCESSFULLY"
        echo ""
        return 0
    else
        log_error "DEPLOYMENT FAILED - ${FAILED_FILES} file(s) with errors"
        echo ""
        if [[ "${CONTINUE_ON_ERROR}" == "true" ]]; then
            log_info "Some deployments succeeded (--continue mode)"
        fi
        return 1
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Create backup directory
    mkdir -p "${BACKUP_DIR}"
    touch "${LOG_FILE}"

    log_section "PERSEUS DATABASE MIGRATION - BATCH DEPLOYMENT"
    log_info "Started at: $(date '+%Y-%m-%d %H:%M:%S')"

    # Parse arguments
    if [[ $# -eq 0 ]]; then
        log_error "No arguments provided"
        echo ""
        show_usage
        exit 2
    fi

    local -a deploy_files=()
    local mode=""

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_usage
                exit 0
                ;;
            --continue)
                CONTINUE_ON_ERROR=true
                log_info "Continue-on-error mode enabled"
                shift
                ;;
            --skip-syntax)
                SKIP_SYNTAX_CHECK=true
                log_warning "Syntax validation disabled (not recommended)"
                shift
                ;;
            --skip-deps)
                SKIP_DEPENDENCY_CHECK=true
                log_warning "Dependency validation disabled (not recommended)"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                log_info "DRY RUN mode enabled (validation only)"
                shift
                ;;
            --dir)
                if [[ $# -lt 2 ]]; then
                    log_error "--dir requires a directory path"
                    exit 2
                fi
                mode="dir"
                collect_files_from_directory deploy_files "$2"
                shift 2
                ;;
            --list)
                if [[ $# -lt 2 ]]; then
                    log_error "--list requires a file path"
                    exit 2
                fi
                mode="list"
                collect_files_from_list deploy_files "$2"
                shift 2
                ;;
            --all)
                mode="all"
                collect_all_files_in_order deploy_files
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                echo ""
                show_usage
                exit 2
                ;;
            *)
                # Individual files
                if [[ -z "${mode}" ]]; then
                    mode="files"
                fi
                break
                ;;
        esac
    done

    # Collect remaining arguments as files
    if [[ "${mode}" == "files" ]]; then
        collect_files_from_args deploy_files "$@"
    fi

    # Validate we have files to deploy
    if [[ ${#deploy_files[@]} -eq 0 ]]; then
        log_error "No SQL files to deploy"
        exit 2
    fi

    # Setup database connection
    detect_execution_mode
    load_password
    check_database

    # Run dependency check (if not skipped)
    check_dependencies

    # Deploy each file
    log_section "STARTING BATCH DEPLOYMENT (${#deploy_files[@]} files)"

    local total_to_deploy=${#deploy_files[@]}
    local current=0

    for file in "${deploy_files[@]}"; do
        current=$((current + 1))
        TOTAL_FILES=$total_to_deploy

        log_info "Progress: ${current}/${total_to_deploy}"

        if deploy_file "${file}"; then
            log_success "Deployment ${current}/${total_to_deploy} completed"
        else
            log_error "Deployment ${current}/${total_to_deploy} failed"

            if [[ "${CONTINUE_ON_ERROR}" == "false" ]]; then
                log_error "Stopping deployment (use --continue to continue on error)"
                print_deployment_summary
                exit 1
            else
                log_warning "Continuing to next file (--continue mode)"
            fi
        fi
    done

    # Print summary
    print_deployment_summary
}

# Run main function
main "$@"
