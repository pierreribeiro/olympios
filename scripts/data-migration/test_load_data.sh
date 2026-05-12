#!/usr/bin/env bash
# =============================================================================
# Test Script: load_data.sh verification
# =============================================================================
# Purpose: Verify load_data.sh structure, CLI behaviour, pre-flight checks,
#          and (optionally) end-to-end loading against a real PostgreSQL.
#
# Usage:
#   ./test_load_data.sh                  # Run offline tests only
#   ./test_load_data.sh --integration    # Also run DB integration tests
#
# The integration tests require a running PostgreSQL instance reachable via
# the same .env / .pgpass configuration that load_data.sh uses.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOAD_SCRIPT="${SCRIPT_DIR}/load_data.sh"
ENV_EXAMPLE="${SCRIPT_DIR}/.env.example"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0
SKIPPED=0

# Temp dir for mock data (cleaned up on exit)
TMPDIR_TEST=""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
pass() { echo -e "  ${GREEN}PASS${NC}  $1"; PASSED=$((PASSED + 1)); }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; FAILED=$((FAILED + 1)); }
skip() { echo -e "  ${YELLOW}SKIP${NC}  $1"; SKIPPED=$((SKIPPED + 1)); }

# Run a sub-command in an isolated env so it cannot touch real data.
# Captures stdout+stderr; sets $OUTPUT and $EXIT_CODE.
run_isolated() {
    local tmplog
    tmplog=$(mktemp)
    set +e
    OUTPUT=$(
        env -i HOME="${HOME}" PATH="${PATH}" TERM="${TERM:-dumb}" \
            bash "$@" >"${tmplog}" 2>&1 && cat "${tmplog}" || cat "${tmplog}"
    )
    EXIT_CODE=$?
    # Re-read in case the env -i wrapper swallowed output
    if [[ -z "${OUTPUT}" && -s "${tmplog}" ]]; then
        OUTPUT=$(cat "${tmplog}")
    fi
    set -e
    rm -f "${tmplog}"
}

cleanup() {
    if [[ -n "${TMPDIR_TEST}" && -d "${TMPDIR_TEST}" ]]; then
        rm -rf "${TMPDIR_TEST}"
    fi
}
trap cleanup EXIT

# Create a minimal temp .env + data dir with mock CSVs.
setup_mock_env() {
    TMPDIR_TEST=$(mktemp -d)
    local mock_data="${TMPDIR_TEST}/data"
    local mock_logs="${TMPDIR_TEST}/logs"
    mkdir -p "${mock_data}" "${mock_logs}"

    # Create a few realistic mock CSV files (tier 0 tables)
    echo '1,read,true' > "${mock_data}/##perseus_tier_0_permissions.csv"
    echo '1,units'     > "${mock_data}/##perseus_tier_0_unit.csv"
    # An intentionally empty CSV
    touch "${mock_data}/##perseus_tier_0_poll.csv"

    # Mock .env pointing at the temp dirs
    cat > "${TMPDIR_TEST}/.env" <<EOF
PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=perseus_dev
PG_USER=perseus_admin
PG_SCHEMA=perseus
DATA_DIR=${mock_data}
LOG_DIR=${mock_logs}
EOF
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
RUN_INTEGRATION=false
if [[ "${1:-}" == "--integration" ]]; then
    RUN_INTEGRATION=true
fi

# ===========================================================================
echo ""
echo "=========================================="
echo "TEST SUITE: load_data.sh"
echo "=========================================="
echo ""

# ===========================================================================
# Section 1 — Script structure
# ===========================================================================
echo "--- Script Structure ---"

# 1.1 File exists
if [[ -f "${LOAD_SCRIPT}" ]]; then
    pass "load_data.sh exists"
else
    fail "load_data.sh not found at ${LOAD_SCRIPT}"
fi

# 1.2 Executable
if [[ -x "${LOAD_SCRIPT}" ]]; then
    pass "load_data.sh is executable"
else
    fail "load_data.sh is not executable (chmod +x needed)"
fi

# 1.3 Bash syntax check
if bash -n "${LOAD_SCRIPT}" 2>/dev/null; then
    pass "bash -n syntax check"
else
    fail "bash -n syntax check"
fi

# 1.4 Shebang
if head -1 "${LOAD_SCRIPT}" | grep -q '#!/usr/bin/env bash'; then
    pass "shebang is #!/usr/bin/env bash"
else
    fail "shebang mismatch"
fi

# 1.5 set -euo pipefail
if grep -q 'set -euo pipefail' "${LOAD_SCRIPT}"; then
    pass "strict mode (set -euo pipefail)"
else
    fail "missing set -euo pipefail"
fi

echo ""

# ===========================================================================
# Section 2 — Key code patterns
# ===========================================================================
echo "--- Key Code Patterns ---"

# 2.1 No docker exec calls
if grep -q 'docker exec' "${LOAD_SCRIPT}"; then
    fail "contains 'docker exec' (should use psql directly)"
else
    pass "no docker exec calls"
fi

# 2.2 Uses \copy (client-side)
if grep -q '\\copy' "${LOAD_SCRIPT}"; then
    pass "uses \\copy (client-side COPY)"
else
    fail "missing \\copy usage"
fi

# 2.3 .pgpass referenced (documentation/error messages)
if grep -qi 'pgpass' "${LOAD_SCRIPT}"; then
    pass ".pgpass referenced in script"
else
    fail "no mention of .pgpass"
fi

# 2.4 Sources .env
if grep -q 'source.*ENV_FILE\|source.*\.env' "${LOAD_SCRIPT}"; then
    pass "sources .env file"
else
    fail "does not source .env"
fi

# 2.5 EXIT trap registered
if grep -q 'trap.*EXIT' "${LOAD_SCRIPT}"; then
    pass "EXIT trap registered (cleanup/FK re-enable)"
else
    fail "no EXIT trap found"
fi

# 2.6 session_replication_role used
if grep -q 'session_replication_role' "${LOAD_SCRIPT}"; then
    pass "uses session_replication_role for FK deferral"
else
    fail "missing session_replication_role"
fi

# 2.7 ALTER TABLE fallback present
if grep -q 'DISABLE TRIGGER ALL' "${LOAD_SCRIPT}" && grep -q 'ENABLE TRIGGER ALL' "${LOAD_SCRIPT}"; then
    pass "ALTER TABLE TRIGGER fallback present"
else
    fail "missing ALTER TABLE TRIGGER fallback"
fi

echo ""

# ===========================================================================
# Section 3 — Tier table completeness
# ===========================================================================
echo "--- Tier Table Completeness ---"

count_tier_tables() {
    local var_name="$1"
    # Count entries between the array declaration and the closing ')'
    local count
    count=$(sed -n "/^${var_name}=(/,/^)/p" "${LOAD_SCRIPT}" | grep -c '"' || true)
    echo "${count}"
}

TIER0_COUNT=$(count_tier_tables "TIER0_TABLES")
TIER1_COUNT=$(count_tier_tables "TIER1_TABLES")
TIER2_COUNT=$(count_tier_tables "TIER2_TABLES")
TIER3_COUNT=$(count_tier_tables "TIER3_TABLES")
TIER4_COUNT=$(count_tier_tables "TIER4_TABLES")
TOTAL=$((TIER0_COUNT + TIER1_COUNT + TIER2_COUNT + TIER3_COUNT + TIER4_COUNT))

[[ "${TIER0_COUNT}" -eq 32 ]] && pass "Tier 0: ${TIER0_COUNT} tables" || fail "Tier 0: expected 32, got ${TIER0_COUNT}"
[[ "${TIER1_COUNT}" -eq 9  ]] && pass "Tier 1: ${TIER1_COUNT} tables"  || fail "Tier 1: expected 9, got ${TIER1_COUNT}"
[[ "${TIER2_COUNT}" -eq 11 ]] && pass "Tier 2: ${TIER2_COUNT} tables" || fail "Tier 2: expected 11, got ${TIER2_COUNT}"
[[ "${TIER3_COUNT}" -eq 12 ]] && pass "Tier 3: ${TIER3_COUNT} tables" || fail "Tier 3: expected 12, got ${TIER3_COUNT}"
[[ "${TIER4_COUNT}" -eq 11 ]] && pass "Tier 4: ${TIER4_COUNT} tables" || fail "Tier 4: expected 11, got ${TIER4_COUNT}"
[[ "${TOTAL}" -eq 75 ]]       && pass "Total:  ${TOTAL} tables"       || fail "Total: expected 75, got ${TOTAL}"

echo ""

# ===========================================================================
# Section 4 — CLI argument handling
# ===========================================================================
echo "--- CLI Argument Handling ---"

# 4.1 --help exits 0 and shows usage
set +e
HELP_OUTPUT=$(bash "${LOAD_SCRIPT}" --help 2>&1)
HELP_EXIT=$?
set -e
if [[ "${HELP_EXIT}" -eq 0 ]] && echo "${HELP_OUTPUT}" | grep -q 'Usage:'; then
    pass "--help exits 0 with usage text"
else
    fail "--help (exit=${HELP_EXIT})"
fi

# 4.2 Invalid tier rejected
set +e
bash "${LOAD_SCRIPT}" --tier 9 >/dev/null 2>&1
TIER_EXIT=$?
set -e
if [[ "${TIER_EXIT}" -ne 0 ]]; then
    pass "--tier 9 rejected (exit ${TIER_EXIT})"
else
    fail "--tier 9 should be rejected"
fi

# 4.3 --tier without value rejected
set +e
bash "${LOAD_SCRIPT}" --tier 2>/dev/null
TIER_NOVAL_EXIT=$?
set -e
if [[ "${TIER_NOVAL_EXIT}" -ne 0 ]]; then
    pass "--tier (no value) rejected (exit ${TIER_NOVAL_EXIT})"
else
    fail "--tier without value should fail"
fi

# 4.4 Unknown option rejected
set +e
bash "${LOAD_SCRIPT}" --foobar >/dev/null 2>&1
UNK_EXIT=$?
set -e
if [[ "${UNK_EXIT}" -ne 0 ]]; then
    pass "--foobar (unknown) rejected (exit ${UNK_EXIT})"
else
    fail "unknown option should be rejected"
fi

echo ""

# ===========================================================================
# Section 5 — Pre-flight check behaviour (with mock env)
# ===========================================================================
echo "--- Pre-flight Checks (mock environment) ---"

setup_mock_env

# 5.1 Missing DATA_DIR detected
set +e
DATA_DIR="/nonexistent/path" LOG_DIR="${TMPDIR_TEST}/logs" \
    bash "${LOAD_SCRIPT}" >/dev/null 2>&1
MISS_DIR_EXIT=$?
set -e
if [[ "${MISS_DIR_EXIT}" -ne 0 ]]; then
    pass "missing DATA_DIR detected (exit ${MISS_DIR_EXIT})"
else
    fail "should fail when DATA_DIR does not exist"
fi

# 5.2 Empty DATA_DIR (no CSVs) detected
EMPTY_DIR=$(mktemp -d)
set +e
DATA_DIR="${EMPTY_DIR}" LOG_DIR="${TMPDIR_TEST}/logs" \
    bash "${LOAD_SCRIPT}" >/dev/null 2>&1
EMPTY_DIR_EXIT=$?
set -e
rm -rf "${EMPTY_DIR}"
if [[ "${EMPTY_DIR_EXIT}" -ne 0 ]]; then
    pass "empty DATA_DIR (no CSVs) detected (exit ${EMPTY_DIR_EXIT})"
else
    fail "should fail when DATA_DIR has no CSV files"
fi

echo ""

# ===========================================================================
# Section 6 — .env.example completeness
# ===========================================================================
echo "--- .env.example Completeness ---"

if [[ -f "${ENV_EXAMPLE}" ]]; then
    for var in PG_HOST PG_PORT PG_DATABASE PG_USER PG_SCHEMA DATA_DIR LOG_DIR; do
        if grep -q "^${var}=" "${ENV_EXAMPLE}"; then
            pass "${var} defined in .env.example"
        else
            fail "${var} missing from .env.example"
        fi
    done
else
    fail ".env.example not found"
fi

echo ""

# ===========================================================================
# Section 7 — Integration tests (requires live PostgreSQL)
# ===========================================================================
if [[ "${RUN_INTEGRATION}" == "true" ]]; then
    echo "--- Integration Tests (live PostgreSQL) ---"

    # Load .env if available to get connection settings
    if [[ -f "${SCRIPT_DIR}/.env" ]]; then
        set -a; source "${SCRIPT_DIR}/.env"; set +a
    fi

    PG_HOST="${PG_HOST:-localhost}"
    PG_PORT="${PG_PORT:-5432}"
    PG_DATABASE="${PG_DATABASE:-perseus_dev}"
    PG_USER="${PG_USER:-perseus_admin}"
    PG_SCHEMA="${PG_SCHEMA:-perseus}"

    PSQL_CMD=(psql -h "${PG_HOST}" -p "${PG_PORT}" -U "${PG_USER}" -d "${PG_DATABASE}" -v "ON_ERROR_STOP=1")

    # 7.1 Connectivity
    if "${PSQL_CMD[@]}" -c "SELECT 1;" &>/dev/null; then
        pass "database connectivity (${PG_HOST}:${PG_PORT}/${PG_DATABASE})"
    else
        fail "database connectivity"
        echo -e "  ${YELLOW}Skipping remaining integration tests${NC}"
        SKIPPED=$((SKIPPED + 1))
        # Jump to summary
        RUN_INTEGRATION=false
    fi

    if [[ "${RUN_INTEGRATION}" == "true" ]]; then
        # 7.2 Schema exists
        SCHEMA_EXISTS=$("${PSQL_CMD[@]}" -tAc \
            "SELECT 1 FROM information_schema.schemata WHERE schema_name = '${PG_SCHEMA}';" 2>/dev/null || true)
        if [[ "${SCHEMA_EXISTS}" == "1" ]]; then
            pass "schema '${PG_SCHEMA}' exists"
        else
            fail "schema '${PG_SCHEMA}' not found"
        fi

        # 7.3 session_replication_role settable
        if "${PSQL_CMD[@]}" -c "SET session_replication_role = 'replica'; SET session_replication_role = 'origin';" &>/dev/null; then
            pass "session_replication_role is settable"
        else
            skip "session_replication_role not settable (ALTER TABLE fallback will be used)"
        fi

        # 7.4 Tables exist for at least tier 0
        TABLE_COUNT=$("${PSQL_CMD[@]}" -tAc \
            "SELECT COUNT(*) FROM information_schema.tables
             WHERE table_schema = '${PG_SCHEMA}';" 2>/dev/null || echo "0")
        TABLE_COUNT="${TABLE_COUNT// /}"
        if [[ "${TABLE_COUNT}" -gt 0 ]]; then
            pass "${TABLE_COUNT} tables found in schema '${PG_SCHEMA}'"
        else
            fail "no tables found in schema '${PG_SCHEMA}'"
        fi

        # 7.5 FK constraints present
        FK_COUNT=$("${PSQL_CMD[@]}" -tAc \
            "SELECT COUNT(*) FROM information_schema.table_constraints
             WHERE constraint_schema = '${PG_SCHEMA}' AND constraint_type = 'FOREIGN KEY';" 2>/dev/null || echo "0")
        FK_COUNT="${FK_COUNT// /}"
        if [[ "${FK_COUNT}" -gt 0 ]]; then
            pass "${FK_COUNT} FK constraints found"
        else
            skip "no FK constraints (may be expected if schema is empty)"
        fi

        # 7.6 --validate-only runs without error
        set +e
        VOUT=$(DATA_DIR="${TMPDIR_TEST}/data" bash "${LOAD_SCRIPT}" --validate-only 2>&1)
        VEXIT=$?
        set -e
        if [[ "${VEXIT}" -eq 0 ]]; then
            pass "--validate-only runs successfully"
        else
            fail "--validate-only failed (exit ${VEXIT})"
        fi
    fi

    echo ""
else
    echo "--- Integration Tests ---"
    skip "Skipped (run with --integration to enable)"
    echo ""
fi

# ===========================================================================
# Summary
# ===========================================================================
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo -e "  Passed:  ${GREEN}${PASSED}${NC}"
echo -e "  Failed:  ${RED}${FAILED}${NC}"
echo -e "  Skipped: ${YELLOW}${SKIPPED}${NC}"
echo ""

if [[ "${FAILED}" -eq 0 ]]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
    exit 0
else
    echo -e "${RED}❌ ${FAILED} TEST(S) FAILED${NC}"
    exit 1
fi
