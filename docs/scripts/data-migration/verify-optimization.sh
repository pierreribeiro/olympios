#!/bin/bash
# ============================================================================
# Verification Script: Large Table Optimization Changes
# ============================================================================
# Purpose: Verify that extract-tier-0.sql has correct optimizations applied
# Date: 2026-02-04
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRACT_FILE="${SCRIPT_DIR}/extract-tier-0.sql"

echo "=========================================="
echo "VERIFICATION: Large Table Optimization"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# ============================================================================
# Test 1: Check m_upstream sample rate is 5%
# ============================================================================
echo -n "Test 1: m_upstream uses 5% sample rate ... "
if grep -q "FROM dbo.m_upstream" "$EXTRACT_FILE" && \
   grep -A 1 "FROM dbo.m_upstream" "$EXTRACT_FILE" | grep -q "TABLESAMPLE(5 PERCENT)"; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: TABLESAMPLE(5 PERCENT) after FROM dbo.m_upstream"
    FAILED=$((FAILED + 1))
fi

# ============================================================================
# Test 2: Check m_upstream has explanatory comment
# ============================================================================
echo -n "Test 2: m_upstream has size explanation comment ... "
if grep -q "686M rows, 153GB" "$EXTRACT_FILE" && \
   grep -q "5% sample applied due to table size" "$EXTRACT_FILE"; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: Comment about 686M rows, 153GB and 5% sample"
    FAILED=$((FAILED + 1))
fi

# ============================================================================
# Test 3: Check Scraper uses File=NULL
# ============================================================================
echo -n "Test 3: Scraper excludes File BLOB with NULL cast ... "
if grep -q "CAST(NULL AS varbinary(max)) AS File" "$EXTRACT_FILE"; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: CAST(NULL AS varbinary(max)) AS File"
    FAILED=$((FAILED + 1))
fi

# ============================================================================
# Test 4: Check Scraper uses 5% sample
# ============================================================================
echo -n "Test 4: Scraper uses 5% sample rate (ID % 20 = 0) ... "
if grep -A 20 "##perseus_tier_0_Scraper" "$EXTRACT_FILE" | grep -q "WHERE ID % 20 = 0"; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: WHERE ID % 20 = 0 for Scraper"
    FAILED=$((FAILED + 1))
fi

# ============================================================================
# Test 5: Check Scraper has BLOB exclusion comments
# ============================================================================
echo -n "Test 5: Scraper has BLOB exclusion explanation ... "
if grep -q "78GB source" "$EXTRACT_FILE" && \
   grep -q "File column set to NULL - BLOB excluded" "$EXTRACT_FILE" && \
   grep -q "445KB" "$EXTRACT_FILE"; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: Comments about 78GB, BLOB exclusion, and 445KB avg row"
    FAILED=$((FAILED + 1))
fi

# ============================================================================
# Test 6: Check m_downstream still uses 15% (unchanged)
# ============================================================================
echo -n "Test 6: m_downstream keeps 15% sample rate ... "
if grep -q "FROM dbo.m_downstream" "$EXTRACT_FILE" && \
   grep -A 1 "FROM dbo.m_downstream" "$EXTRACT_FILE" | grep -q "TABLESAMPLE(15 PERCENT)"; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    echo "  Expected: TABLESAMPLE(15 PERCENT) for m_downstream (unchanged)"
    FAILED=$((FAILED + 1))
fi

# ============================================================================
# Test 7: Verify file exists and is readable
# ============================================================================
echo -n "Test 7: extract-tier-0.sql exists and is readable ... "
if [[ -f "$EXTRACT_FILE" && -r "$EXTRACT_FILE" ]]; then
    echo -e "${GREEN}PASS${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    echo "  File not found or not readable: $EXTRACT_FILE"
    FAILED=$((FAILED + 1))
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=========================================="
echo "VERIFICATION SUMMARY"
echo "=========================================="
echo "Tests Passed: ${GREEN}${PASSED}${NC}"
echo "Tests Failed: ${RED}${FAILED}${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
    echo ""
    echo "Optimization changes verified successfully!"
    echo ""
    echo "Expected Performance:"
    echo "  - m_upstream: 4h20min → 1h30min (65% reduction)"
    echo "  - Scraper: 2-3h → <30 sec (99% reduction)"
    echo "  - Total: >4h30min → 2h20min (48% reduction)"
    echo "  - Safety buffer: 130 minutes"
    echo ""
    echo "Ready to execute: ./extract-data.sh"
    exit 0
else
    echo -e "${RED}❌ VERIFICATION FAILED${NC}"
    echo ""
    echo "Please review the failed tests above."
    echo "Changes may not have been applied correctly."
    exit 1
fi
