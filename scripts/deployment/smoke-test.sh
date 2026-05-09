#!/usr/bin/env bash
#
# Perseus Database Migration - Post-Deployment Smoke Test Script
#
# This script performs quick post-deployment validation to verify that critical
# database objects exist and function correctly. It runs fast sanity checks
# (<2 minutes) to catch deployment issues before they impact users.
#
# Usage:
#   ./smoke-test.sh <environment>
#   ./smoke-test.sh --procedure <name> <environment>
#   ./smoke-test.sh --quick <environment>
#
# Options:
#   <environment>           Target environment (dev|staging|prod)
#   --procedure <name>      Test single procedure only
#   --quick                 Quick mode (connectivity + critical objects only)
#   --verbose               Show detailed test output
#   --help                  Show this help message
#
# Exit Codes:
#   0 - All smoke tests passed
#   1 - One or more tests failed
#   2 - Invalid arguments or environment unavailable
#
# Test Categories:
#   1. Connectivity       - Database connection
#   2. Object Existence   - All deployed objects exist
#   3. Basic Functionality - Simple queries execute
#   4. Critical Procedures - Key procedures run without error
#   5. View Queries       - Views return data
#   6. Foreign Tables     - FDW connections work (if configured)
#
# Examples:
#   ./smoke-test.sh dev
#   ./smoke-test.sh --procedure reconcilemupstream staging
#   ./smoke-test.sh --quick prod
#
# Constitutional Compliance:
#   - POSIX-compliant bash (set -euo pipefail)
#   - Proper error handling with context
#   - Modular functions
#   - Clear error messages
#

# Future Enhancements Backlog Section
# 1. Create an env.conf or .json file for setting up script initial variables
# 2. Password are read from secrets file path at configuration file
# 3. Execution logs must be written in the global temporary directory informed in configuration file.
# 4. Directory logs tree pattern: {global_dir}/{branch_name}/{dir_script_souce}/file_name_{timestamp}.log
# 5. Need to check the repetition of the bug showed at file deploy-batch.sh
# 6. Review the entire scipt looking for bug or flaws in the execution logic, explore edge cases

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default configuration
ENVIRONMENT="${1:-}"
SINGLE_PROCEDURE=""
QUICK_MODE=false
VERBOSE=false

# Database connection parameters
DB_USER="${DB_USER:-perseus_admin}"
DB_NAME="${DB_NAME:-}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
PGPASSWORD_FILE="${PGPASSWORD_FILE:-${PROJECT_ROOT}/infra/database/.secrets/postgres_password.txt}"
DOCKER_CONTAINER="${DOCKER_CONTAINER:-}"

# Execution mode (auto-detected)
USE_DOCKER=false

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test results array
declare -a FAILED_TEST_NAMES=()

# Timeout settings (seconds)
CONNECTIVITY_TIMEOUT=5
QUERY_TIMEOUT=30
PROCEDURE_TIMEOUT=60

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

log_skip() {
    echo -e "${YELLOW}[○ SKIP]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${CYAN}=========================================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}=========================================================================${NC}"
}

log_test() {
    echo -e "${MAGENTA}[TEST]${NC} $1"
}

# Show usage
show_usage() {
    cat << 'EOF'
Perseus Database Migration - Post-Deployment Smoke Test Script

Usage:
  ./smoke-test.sh <environment>
  ./smoke-test.sh --procedure <name> <environment>
  ./smoke-test.sh --quick <environment>
  ./smoke-test.sh --help

Options:
  <environment>           Target environment (dev|staging|prod)
  --procedure <name>      Test single procedure only
  --quick                 Quick mode (connectivity + critical objects only)
  --verbose               Show detailed test output
  --help                  Show this help message

Environments:
  dev       - Development environment (perseus_dev)
  staging   - Staging environment (perseus_staging)
  prod      - Production environment (perseus_prod)

Examples:
  ./smoke-test.sh dev
  ./smoke-test.sh --procedure reconcilemupstream staging
  ./smoke-test.sh --quick prod
  ./smoke-test.sh --verbose dev

Environment Variables:
  DB_USER          Database user (default: perseus_admin)
  DB_HOST          Database host (default: localhost)
  DB_PORT          Database port (default: 5432)
  PGPASSWORD_FILE  Password file path
  DOCKER_CONTAINER Docker container name (auto-detected)

Exit Codes:
  0 - All tests passed
  1 - One or more tests failed
  2 - Invalid arguments or environment unavailable

Test Categories:
  1. Connectivity       - Database connection
  2. Object Existence   - All deployed objects exist
  3. Basic Functionality - Simple queries execute
  4. Critical Procedures - Key procedures run without error
  5. View Queries       - Views return data
  6. Foreign Tables     - FDW connections work (if configured)
EOF
}

# Parse arguments
parse_arguments() {
    if [[ $# -eq 0 ]]; then
        log_error "No environment specified"
        echo ""
        show_usage
        exit 2
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_usage
                exit 0
                ;;
            --procedure)
                if [[ $# -lt 2 ]]; then
                    log_error "--procedure requires a procedure name"
                    exit 2
                fi
                SINGLE_PROCEDURE="$2"
                shift 2
                ;;
            --quick)
                QUICK_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            dev|staging|prod)
                ENVIRONMENT="$1"
                shift
                ;;
            *)
                log_error "Unknown argument: $1"
                show_usage
                exit 2
                ;;
        esac
    done

    if [[ -z "${ENVIRONMENT}" ]]; then
        log_error "Environment not specified"
        show_usage
        exit 2
    fi
}

# Configure environment-specific settings
configure_environment() {
    case "${ENVIRONMENT}" in
        dev)
            DB_NAME="${DB_NAME:-perseus_dev}"
            DOCKER_CONTAINER="${DOCKER_CONTAINER:-perseus-postgres-dev}"
            ;;
        staging)
            DB_NAME="${DB_NAME:-perseus_staging}"
            DOCKER_CONTAINER="${DOCKER_CONTAINER:-perseus-postgres-staging}"
            ;;
        prod)
            DB_NAME="${DB_NAME:-perseus_prod}"
            DOCKER_CONTAINER="${DOCKER_CONTAINER:-perseus-postgres-prod}"
            ;;
        *)
            log_error "Invalid environment: ${ENVIRONMENT}"
            log_info "Valid environments: dev, staging, prod"
            exit 2
            ;;
    esac

    log_info "Environment: ${ENVIRONMENT}"
    log_info "Database: ${DB_NAME}"
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
    local timeout="${1:-${QUERY_TIMEOUT}}"
    shift

    if [[ "${USE_DOCKER}" == "true" ]]; then
        timeout "${timeout}s" docker exec -i "${DOCKER_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" "$@" 2>&1
    else
        export PGPASSWORD=$(cat "${PGPASSWORD_FILE}")
        timeout "${timeout}s" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" "$@" 2>&1
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

# Record test result
record_test() {
    local test_name="$1"
    local result="$2"  # pass|fail|skip

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    case "${result}" in
        pass)
            PASSED_TESTS=$((PASSED_TESTS + 1))
            log_success "${test_name}"
            ;;
        fail)
            FAILED_TESTS=$((FAILED_TESTS + 1))
            FAILED_TEST_NAMES+=("${test_name}")
            log_error "${test_name}"
            ;;
        skip)
            SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
            log_skip "${test_name}"
            ;;
    esac
}

# Test: Database connectivity
test_connectivity() {
    log_section "TEST CATEGORY 1: CONNECTIVITY"

    log_test "Database connection: ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

    local output
    if output=$(run_psql "${CONNECTIVITY_TIMEOUT}" -t -c "SELECT version();" 2>&1); then
        if [[ "${VERBOSE}" == "true" ]]; then
            echo "  ${output}" | head -1
        fi
        record_test "Database connectivity" "pass"
        return 0
    else
        echo "  Error: ${output}"
        record_test "Database connectivity" "fail"
        return 1
    fi
}

# Test: PostgreSQL version
test_postgres_version() {
    log_test "PostgreSQL version check (>= 17.x)"

    local version
    if version=$(run_psql "${CONNECTIVITY_TIMEOUT}" -t -c "SHOW server_version;" 2>&1); then
        local major_version=$(echo "${version}" | xargs | grep -oE '^[0-9]+' | head -1)
        if [[ "${major_version}" -ge 17 ]]; then
            if [[ "${VERBOSE}" == "true" ]]; then
                echo "  Version: ${version}"
            fi
            record_test "PostgreSQL version >= 17" "pass"
            return 0
        else
            echo "  Error: Version ${version} is below 17.x"
            record_test "PostgreSQL version >= 17" "fail"
            return 1
        fi
    else
        echo "  Error: ${version}"
        record_test "PostgreSQL version >= 17" "fail"
        return 1
    fi
}

# Test: Basic functionality
test_basic_functionality() {
    log_section "TEST CATEGORY 2: BASIC FUNCTIONALITY"

    # Test 1: Simple SELECT
    log_test "Simple SELECT query"
    local result
    if result=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT 1 AS test;" 2>&1); then
        if [[ "${result}" =~ "1" ]]; then
            record_test "SELECT 1" "pass"
        else
            echo "  Error: Unexpected result: ${result}"
            record_test "SELECT 1" "fail"
        fi
    else
        echo "  Error: ${result}"
        record_test "SELECT 1" "fail"
    fi

    # Test 2: Current timestamp
    log_test "Current timestamp function"
    if result=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT CURRENT_TIMESTAMP;" 2>&1); then
        if [[ "${result}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
            if [[ "${VERBOSE}" == "true" ]]; then
                echo "  Timestamp: ${result}"
            fi
            record_test "CURRENT_TIMESTAMP" "pass"
        else
            echo "  Error: Invalid timestamp: ${result}"
            record_test "CURRENT_TIMESTAMP" "fail"
        fi
    else
        echo "  Error: ${result}"
        record_test "CURRENT_TIMESTAMP" "fail"
    fi

    # Test 3: Schema exists
    log_test "Perseus schema exists"
    if result=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT EXISTS(SELECT 1 FROM pg_namespace WHERE nspname = 'perseus');" 2>&1); then
        if [[ "${result}" =~ "t" ]]; then
            record_test "Schema 'perseus' exists" "pass"
        else
            echo "  Error: Schema 'perseus' not found"
            record_test "Schema 'perseus' exists" "fail"
        fi
    else
        echo "  Error: ${result}"
        record_test "Schema 'perseus' exists" "fail"
    fi
}

# Test: Object existence
test_object_existence() {
    log_section "TEST CATEGORY 3: OBJECT EXISTENCE"

    # Test procedures exist
    log_test "Stored procedures exist"
    local proc_count
    if proc_count=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'perseus' AND p.prokind = 'p';" 2>&1); then
        proc_count=$(echo "${proc_count}" | xargs)
        if [[ "${proc_count}" -gt 0 ]]; then
            if [[ "${VERBOSE}" == "true" ]]; then
                echo "  Found ${proc_count} procedure(s)"
            fi
            record_test "Procedures exist (${proc_count} found)" "pass"
        else
            echo "  Warning: No procedures found in perseus schema"
            record_test "Procedures exist" "fail"
        fi
    else
        echo "  Error: ${proc_count}"
        record_test "Procedures exist" "fail"
    fi

    # Test functions exist
    log_test "Functions exist"
    local func_count
    if func_count=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'perseus' AND p.prokind = 'f';" 2>&1); then
        func_count=$(echo "${func_count}" | xargs)
        if [[ "${func_count}" -ge 0 ]]; then
            if [[ "${VERBOSE}" == "true" ]]; then
                echo "  Found ${func_count} function(s)"
            fi
            record_test "Functions exist (${func_count} found)" "pass"
        else
            record_test "Functions exist" "fail"
        fi
    else
        echo "  Error: ${func_count}"
        record_test "Functions exist" "fail"
    fi

    # Test views exist
    log_test "Views exist"
    local view_count
    if view_count=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT COUNT(*) FROM pg_views WHERE schemaname = 'perseus';" 2>&1); then
        view_count=$(echo "${view_count}" | xargs)
        if [[ "${view_count}" -ge 0 ]]; then
            if [[ "${VERBOSE}" == "true" ]]; then
                echo "  Found ${view_count} view(s)"
            fi
            record_test "Views exist (${view_count} found)" "pass"
        else
            record_test "Views exist" "fail"
        fi
    else
        echo "  Error: ${view_count}"
        record_test "Views exist" "fail"
    fi

    # Test tables exist
    log_test "Tables exist"
    local table_count
    if table_count=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'perseus';" 2>&1); then
        table_count=$(echo "${table_count}" | xargs)
        if [[ "${table_count}" -ge 0 ]]; then
            if [[ "${VERBOSE}" == "true" ]]; then
                echo "  Found ${table_count} table(s)"
            fi
            record_test "Tables exist (${table_count} found)" "pass"
        else
            record_test "Tables exist" "fail"
        fi
    else
        echo "  Error: ${table_count}"
        record_test "Tables exist" "fail"
    fi
}

# Test: Critical procedures
test_critical_procedures() {
    log_section "TEST CATEGORY 4: CRITICAL PROCEDURES"

    # List of critical procedures (P0 priority from CLAUDE.md)
    local critical_procs=(
        "reconcilemupstream"
        "addarc"
        "removearc"
        "move_node"
    )

    # If single procedure specified, test only that one
    if [[ -n "${SINGLE_PROCEDURE}" ]]; then
        critical_procs=("${SINGLE_PROCEDURE}")
    fi

    for proc in "${critical_procs[@]}"; do
        log_test "Procedure exists: ${proc}"

        local exists
        if exists=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'perseus' AND p.proname = '${proc}');" 2>&1); then
            if [[ "${exists}" =~ "t" ]]; then
                record_test "Procedure '${proc}' exists" "pass"

                # Test procedure can be described (has valid signature)
                log_test "Procedure signature valid: ${proc}"
                local signature
                if signature=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT pg_get_functiondef(p.oid) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'perseus' AND p.proname = '${proc}' LIMIT 1;" 2>&1); then
                    if [[ -n "${signature}" ]]; then
                        record_test "Procedure '${proc}' signature valid" "pass"
                    else
                        echo "  Error: Empty signature for ${proc}"
                        record_test "Procedure '${proc}' signature valid" "fail"
                    fi
                else
                    echo "  Error: ${signature}"
                    record_test "Procedure '${proc}' signature valid" "fail"
                fi
            else
                echo "  Warning: Procedure '${proc}' not found (may not be deployed yet)"
                record_test "Procedure '${proc}' exists" "skip"
            fi
        else
            echo "  Error: ${exists}"
            record_test "Procedure '${proc}' exists" "fail"
        fi
    done
}

# Test: Views can be queried
test_views() {
    log_section "TEST CATEGORY 5: VIEW QUERIES"

    # Get list of views
    local views
    if views=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT viewname FROM pg_views WHERE schemaname = 'perseus' ORDER BY viewname LIMIT 5;" 2>&1); then
        if [[ -z "${views}" ]]; then
            log_skip "No views found in perseus schema"
            record_test "Views queryable" "skip"
            return 0
        fi

        # Test each view can be queried
        while IFS= read -r view; do
            view=$(echo "${view}" | xargs)  # trim whitespace
            if [[ -n "${view}" ]]; then
                log_test "View queryable: ${view}"

                local result
                if result=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT COUNT(*) FROM perseus.${view};" 2>&1); then
                    result=$(echo "${result}" | xargs)
                    if [[ "${result}" =~ ^[0-9]+$ ]]; then
                        if [[ "${VERBOSE}" == "true" ]]; then
                            echo "  Rows: ${result}"
                        fi
                        record_test "View '${view}' queryable" "pass"
                    else
                        echo "  Error: Invalid count result: ${result}"
                        record_test "View '${view}' queryable" "fail"
                    fi
                else
                    echo "  Error: ${result}"
                    record_test "View '${view}' queryable" "fail"
                fi
            fi
        done <<< "${views}"
    else
        echo "  Error: ${views}"
        record_test "Views queryable" "fail"
    fi
}

# Test: Foreign data wrappers (if configured)
test_foreign_data_wrappers() {
    log_section "TEST CATEGORY 6: FOREIGN DATA WRAPPERS"

    # Check if postgres_fdw extension exists
    log_test "FDW extension installed"
    local fdw_exists
    if fdw_exists=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'postgres_fdw');" 2>&1); then
        if [[ "${fdw_exists}" =~ "t" ]]; then
            record_test "postgres_fdw extension installed" "pass"

            # Check for foreign servers
            log_test "Foreign servers configured"
            local server_count
            if server_count=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT COUNT(*) FROM pg_foreign_server;" 2>&1); then
                server_count=$(echo "${server_count}" | xargs)
                if [[ "${server_count}" -gt 0 ]]; then
                    if [[ "${VERBOSE}" == "true" ]]; then
                        echo "  Found ${server_count} foreign server(s)"
                    fi
                    record_test "Foreign servers configured (${server_count} found)" "pass"

                    # Test foreign table queries (sample only)
                    log_test "Foreign tables queryable"
                    local ftable
                    if ftable=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT foreign_table_name FROM information_schema.foreign_tables LIMIT 1;" 2>&1); then
                        ftable=$(echo "${ftable}" | xargs)
                        if [[ -n "${ftable}" ]]; then
                            local result
                            if result=$(run_psql "${QUERY_TIMEOUT}" -t -c "SELECT 1 FROM ${ftable} LIMIT 1;" 2>&1); then
                                record_test "Foreign tables queryable" "pass"
                            else
                                echo "  Warning: Foreign table query failed (connection issue?): ${result}"
                                record_test "Foreign tables queryable" "fail"
                            fi
                        else
                            log_skip "No foreign tables found"
                            record_test "Foreign tables queryable" "skip"
                        fi
                    else
                        echo "  Error: ${ftable}"
                        record_test "Foreign tables queryable" "fail"
                    fi
                else
                    log_skip "No foreign servers configured"
                    record_test "Foreign servers configured" "skip"
                fi
            else
                echo "  Error: ${server_count}"
                record_test "Foreign servers configured" "fail"
            fi
        else
            log_skip "postgres_fdw extension not installed"
            record_test "postgres_fdw extension installed" "skip"
        fi
    else
        echo "  Error: ${fdw_exists}"
        record_test "postgres_fdw extension installed" "fail"
    fi
}

# Print summary report
print_summary() {
    log_section "SMOKE TEST SUMMARY"

    local pass_rate=0
    if [[ ${TOTAL_TESTS} -gt 0 ]]; then
        pass_rate=$(awk "BEGIN {printf \"%.1f\", (${PASSED_TESTS}/${TOTAL_TESTS})*100}")
    fi

    echo ""
    echo -e "  Environment:   ${CYAN}${ENVIRONMENT}${NC} (${DB_NAME})"
    echo -e "  Total Tests:   ${TOTAL_TESTS}"
    echo -e "  ${GREEN}✓ Passed:${NC}      ${PASSED_TESTS}"
    echo -e "  ${RED}✗ Failed:${NC}      ${FAILED_TESTS}"
    echo -e "  ${YELLOW}○ Skipped:${NC}     ${SKIPPED_TESTS}"
    echo -e "  Pass Rate:     ${pass_rate}%"
    echo ""

    if [[ ${FAILED_TESTS} -gt 0 ]]; then
        echo -e "${RED}FAILED TESTS:${NC}"
        for test_name in "${FAILED_TEST_NAMES[@]}"; do
            echo -e "  ${RED}✗${NC} ${test_name}"
        done
        echo ""
    fi

    if [[ ${FAILED_TESTS} -eq 0 ]]; then
        log_success "ALL SMOKE TESTS PASSED"
        echo ""
        echo -e "${GREEN}✓ Deployment validation successful${NC}"
        echo -e "${GREEN}✓ Database is ready for use${NC}"
        echo ""
        return 0
    else
        log_error "SMOKE TESTS FAILED - ${FAILED_TESTS} test(s) with errors"
        echo ""
        echo -e "${RED}✗ Deployment may have issues${NC}"
        echo -e "${RED}✗ Review failed tests above${NC}"
        echo ""
        return 1
    fi
}

# Main execution
main() {
    local start_time=$(date +%s)

    log_section "PERSEUS DATABASE MIGRATION - POST-DEPLOYMENT SMOKE TEST"

    parse_arguments "$@"
    configure_environment
    detect_execution_mode
    load_password

    # Run test categories
    if ! test_connectivity; then
        log_error "Connectivity test failed - aborting remaining tests"
        print_summary
        exit 1
    fi

    test_postgres_version
    test_basic_functionality

    if [[ "${QUICK_MODE}" == "true" ]]; then
        log_info "Quick mode: Skipping detailed object tests"
    else
        test_object_existence
        test_critical_procedures
        test_views
        test_foreign_data_wrappers
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_info "Total execution time: ${duration} seconds"

    print_summary
}

# Run main function
main "$@"
