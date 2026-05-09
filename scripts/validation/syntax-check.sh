#!/usr/bin/env bash
#
# Perseus Database Migration - Syntax Validation Script
#
# This script validates PostgreSQL 17 syntax compliance for migrated SQL objects.
# It performs dry-run execution against the development database to catch syntax
# errors before deployment.
#
# Usage:
#   ./syntax-check.sh <file1.sql> [file2.sql ...]
#   ./syntax-check.sh --dir <directory>
#   ./syntax-check.sh --all
#
# Options:
#   <files>      One or more SQL files to validate
#   --dir <path> Validate all .sql files in directory (recursive)
#   --all        Validate all SQL files in source/building/pgsql/refactored/
#   --help       Show this help message
#
# Exit Codes:
#   0 - All files passed syntax validation
#   1 - One or more files failed validation
#   2 - Invalid arguments or missing files
#
# Examples:
#   ./syntax-check.sh source/building/pgsql/refactored/20.\ create-procedure/sp_move_node.sql
#   ./syntax-check.sh --dir source/building/pgsql/refactored/20.\ create-procedure/
#   ./syntax-check.sh --all
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Database connection parameters
DB_USER="${DB_USER:-perseus_admin}"
DB_NAME="${DB_NAME:-perseus_dev}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
PGPASSWORD_FILE="${PGPASSWORD_FILE:-${PROJECT_ROOT}/infra/database/.secrets/postgres_password.txt}"
DOCKER_CONTAINER="${DOCKER_CONTAINER:-perseus-postgres-dev}"

# Execution mode (auto-detected)
USE_DOCKER=false

# Counters
TOTAL_FILES=0
PASSED_FILES=0
FAILED_FILES=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠ WARN]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${CYAN}=========================================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}=========================================================================${NC}"
}

# Show usage
show_usage() {
    cat << 'EOF'
Perseus Database Migration - Syntax Validation Script

Usage:
  ./syntax-check.sh <file1.sql> [file2.sql ...]
  ./syntax-check.sh --dir <directory>
  ./syntax-check.sh --all
  ./syntax-check.sh --help

Options:
  <files>      One or more SQL files to validate
  --dir <path> Validate all .sql files in directory (recursive)
  --all        Validate all SQL files in source/building/pgsql/refactored/
  --help       Show this help message

Examples:
  ./syntax-check.sh source/building/pgsql/refactored/20.\ create-procedure/sp_move_node.sql
  ./syntax-check.sh --dir source/building/pgsql/refactored/20.\ create-procedure/
  ./syntax-check.sh --all

Environment Variables:
  DB_USER       Database user (default: perseus_admin)
  DB_NAME       Database name (default: perseus_dev)
  DB_HOST       Database host (default: localhost)
  DB_PORT       Database port (default: 5432)
  PGPASSWORD_FILE  Password file path

Exit Codes:
  0 - All files passed
  1 - One or more files failed
  2 - Invalid arguments or missing files
EOF
}

# Detect execution mode
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
        log_error "Cannot connect to database"
        log_info "Ensure PostgreSQL container is running: cd infra/database && ./init-db.sh start"
        exit 2
    fi

    log_success "Database connection OK"
}

# Validate single SQL file
validate_file() {
    local file="$1"
    local filename=$(basename "${file}")

    ((TOTAL_FILES++))

    echo ""
    log_info "Validating: ${file}"

    # Check file exists
    if [[ ! -f "${file}" ]]; then
        log_error "File not found: ${file}"
        ((FAILED_FILES++))
        return 1
    fi

    # Create temporary transaction wrapper for dry-run validation
    local temp_file=$(mktemp)
    trap "rm -f ${temp_file}" RETURN

    cat > "${temp_file}" << 'EOF_WRAPPER'
-- Syntax validation dry-run (transaction will be rolled back)
BEGIN;

-- Set error handling to stop on first error
\set ON_ERROR_STOP on

EOF_WRAPPER

    cat "${file}" >> "${temp_file}"

    cat >> "${temp_file}" << 'EOF_WRAPPER'

-- Rollback to prevent any changes
ROLLBACK;
EOF_WRAPPER

    # Execute validation
    local error_output=$(mktemp)
    trap "rm -f ${error_output}" RETURN

    # For Docker mode, copy file to container temp location
    if [[ "${USE_DOCKER}" == "true" ]]; then
        local container_temp="/tmp/syntax_validate_$(basename ${temp_file})"
        docker cp "${temp_file}" "${DOCKER_CONTAINER}:${container_temp}" 2>/dev/null

        if docker exec -i "${DOCKER_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" \
             -f "${container_temp}" > /dev/null 2> "${error_output}"; then
            docker exec "${DOCKER_CONTAINER}" rm -f "${container_temp}" 2>/dev/null || true
            log_success "${filename} - Syntax valid"
            ((PASSED_FILES++))
            return 0
        else
            docker exec "${DOCKER_CONTAINER}" rm -f "${container_temp}" 2>/dev/null || true
            log_error "${filename} - Syntax errors detected:"
            echo ""
            sed 's/^/    /' "${error_output}"
            echo ""
            ((FAILED_FILES++))
            return 1
        fi
    else
        # Local psql execution
        if run_psql -f "${temp_file}" > /dev/null 2> "${error_output}"; then
            log_success "${filename} - Syntax valid"
            ((PASSED_FILES++))
            return 0
        else
            log_error "${filename} - Syntax errors detected:"
            echo ""
            sed 's/^/    /' "${error_output}"
            echo ""
            ((FAILED_FILES++))
            return 1
        fi
    fi
}

# Validate directory
validate_directory() {
    local dir="$1"

    if [[ ! -d "${dir}" ]]; then
        log_error "Directory not found: ${dir}"
        exit 2
    fi

    log_section "VALIDATING DIRECTORY: ${dir}"

    local sql_files=()
    while IFS= read -r -d '' file; do
        sql_files+=("${file}")
    done < <(find "${dir}" -type f -name "*.sql" -print0 | sort -z)

    if [[ ${#sql_files[@]} -eq 0 ]]; then
        log_warning "No .sql files found in ${dir}"
        return 0
    fi

    log_info "Found ${#sql_files[@]} SQL file(s)"

    for file in "${sql_files[@]}"; do
        validate_file "${file}" || true  # Continue on error
    done
}

# Validate all refactored objects
validate_all() {
    local refactored_dir="${PROJECT_ROOT}/source/building/pgsql/refactored"

    if [[ ! -d "${refactored_dir}" ]]; then
        log_error "Refactored directory not found: ${refactored_dir}"
        exit 2
    fi

    log_section "VALIDATING ALL REFACTORED SQL OBJECTS"
    log_info "Directory: ${refactored_dir}"

    # Validate in dependency order (0-21 directories)
    local order_dirs=(
        "0. drop-trigger"
        "1. drop-constraint"
        "2. drop-index"
        "3. drop-view"
        "4. drop-procedure"
        "5. drop-function"
        "6. drop-table"
        "7. drop-domain"
        "8. drop-foreign-table"
        "9. drop-type"
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
            validate_directory "${full_path}"
        fi
    done
}

# Print summary report
print_summary() {
    log_section "VALIDATION SUMMARY"

    echo ""
    echo -e "  Total Files:   ${TOTAL_FILES}"
    echo -e "  ${GREEN}✓ Passed:${NC}      ${PASSED_FILES}"
    echo -e "  ${RED}✗ Failed:${NC}      ${FAILED_FILES}"
    echo ""

    if [[ ${FAILED_FILES} -eq 0 ]]; then
        log_success "ALL SYNTAX VALIDATION PASSED"
        echo ""
        return 0
    else
        log_error "SYNTAX VALIDATION FAILED - ${FAILED_FILES} file(s) with errors"
        echo ""
        return 1
    fi
}

# Main execution
main() {
    log_section "PERSEUS DATABASE MIGRATION - SYNTAX VALIDATION"

    # Parse arguments
    if [[ $# -eq 0 ]]; then
        log_error "No arguments provided"
        echo ""
        show_usage
        exit 2
    fi

    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --all)
            detect_execution_mode
            load_password
            check_database
            validate_all
            print_summary
            ;;
        --dir)
            if [[ $# -lt 2 ]]; then
                log_error "--dir requires a directory path"
                exit 2
            fi
            detect_execution_mode
            load_password
            check_database
            validate_directory "$2"
            print_summary
            ;;
        *)
            # Validate individual files
            detect_execution_mode
            load_password
            check_database

            log_section "VALIDATING SQL FILES"

            for file in "$@"; do
                validate_file "${file}" || true  # Continue on error
            done

            print_summary
            ;;
    esac
}

# Run main function
main "$@"
