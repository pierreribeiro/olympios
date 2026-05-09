# Unit Tests

## 📁 Directory Purpose

This directory contains **unit tests** for individual PostgreSQL procedures. Each test validates that a single procedure works correctly in isolation.

**Test Scope:** Single procedure, mocked dependencies

**Test Framework:** pgTAP (PostgreSQL Test Anything Protocol)

---

## 🎯 Unit Testing Philosophy

**Test Each Procedure in Isolation**

Unit tests should:
- ✅ Test one procedure at a time
- ✅ Mock external dependencies (tables, other procedures)
- ✅ Cover happy path and error cases
- ✅ Execute quickly (<1 second per test)
- ✅ Be deterministic (same input = same output)

**Coverage Goal:** 90%+ code coverage per procedure

---

## 📋 Test Structure

### Standard Test File Template

```sql
-- =============================================================================
-- Unit Test: schema.procedure_name
-- Author: Pierre Ribeiro
-- Created: YYYY-MM-DD
-- Framework: pgTAP
-- =============================================================================

-- Start transaction (auto-rollback after test)
BEGIN;

-- Load pgTAP extension
SELECT plan(10);  -- Number of tests

-- =============================================================================
-- TEST SETUP
-- =============================================================================

-- Create test schema (isolated from production)
CREATE SCHEMA IF NOT EXISTS test;
SET search_path TO test, public;

-- Create mock tables
CREATE TABLE test.M_Upstream (
    MaterialID INT,
    ParentID INT,
    -- ... other columns
);

-- Insert test data
INSERT INTO test.M_Upstream VALUES
    (1, 100, 'Active'),
    (2, 100, 'Inactive'),
    (3, NULL, 'Active');

-- =============================================================================
-- TEST 1: Happy Path
-- =============================================================================

SELECT lives_ok(
    $$SELECT * FROM schema.procedure_name(1, 'test')$$,
    'Procedure executes without error'
);

SELECT results_eq(
    $$SELECT * FROM schema.procedure_name(1, 'test')$$,
    $$VALUES (1, 'expected_result')$$,
    'Returns expected result'
);

-- =============================================================================
-- TEST 2: NULL Parameter Handling
-- =============================================================================

SELECT throws_ok(
    $$SELECT * FROM schema.procedure_name(NULL, 'test')$$,
    'P0001',
    'MaterialID cannot be NULL',
    'Rejects NULL MaterialID'
);

-- =============================================================================
-- TEST 3: Empty Result Set
-- =============================================================================

SELECT results_eq(
    $$SELECT * FROM schema.procedure_name(999, 'test')$$,
    $$SELECT NULL::INT LIMIT 0$$,
    'Returns empty set for non-existent ID'
);

-- =============================================================================
-- TEST 4: Edge Case (Extreme Values)
-- =============================================================================

SELECT is(
    (SELECT COUNT(*) FROM schema.procedure_name(2147483647, 'test')),
    0,
    'Handles maximum INT value'
);

-- =============================================================================
-- TEST CLEANUP
-- =============================================================================

-- Finish test plan
SELECT * FROM finish();

-- Rollback (auto-cleanup)
ROLLBACK;
```

---

## 🔍 Test Categories

### 1. Happy Path Tests
```sql
-- Test normal, expected behavior
SELECT results_eq(
    'SELECT * FROM reconcilemupstream(1, 100)',
    ARRAY[(1, 100, 'Success')],
    'Normal execution returns expected result'
);
```

### 2. Error Handling Tests
```sql
-- Test exception handling
SELECT throws_ok(
    'SELECT * FROM reconcilemupstream(NULL, 100)',
    'P0001',
    'MaterialID cannot be NULL',
    'Throws error on NULL input'
);

SELECT throws_ok(
    'SELECT * FROM reconcilemupstream(-1, 100)',
    '23514',
    'MaterialID must be positive',
    'Validates input range'
);
```

### 3. Edge Case Tests
```sql
-- Test boundaries and extremes
SELECT is(
    (SELECT COUNT(*) FROM reconcilemupstream(0, 0)),
    0,
    'Handles zero values'
);

SELECT is(
    (SELECT COUNT(*) FROM reconcilemupstream(2147483647, 2147483647)),
    0,
    'Handles maximum INT'
);

-- Test empty strings
SELECT throws_ok(
    'SELECT * FROM reconcilemupstream(1, '''')',
    'Empty status not allowed'
);
```

### 4. Data Type Tests
```sql
-- Test type conversions
SELECT is(
    (SELECT result FROM reconcilemupstream(1::BIGINT, 100)),
    expected_value,
    'Handles BIGINT input correctly'
);
```

### 5. Transaction Tests
```sql
-- Test transaction behavior
BEGIN;
    SELECT reconcilemupstream(1, 100);
    SELECT is(
        (SELECT COUNT(*) FROM M_Upstream WHERE MaterialID = 1),
        1,
        'Changes visible within transaction'
    );
ROLLBACK;

-- Verify rollback worked
SELECT is(
    (SELECT COUNT(*) FROM M_Upstream WHERE MaterialID = 1),
    0,
    'Changes rolled back successfully'
);
```

---

## 🛠️ Running Tests

### Single Test
```bash
# Run one test file
psql -h localhost -d postgres -f tests/unit/test_reconcilemupstream.sql

# With output formatting
psql -h localhost -d postgres -f tests/unit/test_reconcilemupstream.sql \
  | grep -E "^(ok|not ok|#)"
```

### All Unit Tests
```bash
# Run all tests in directory
for test in tests/unit/test_*.sql; do
  echo "Running $test..."
  psql -h localhost -d postgres -f "$test"
done

# Or use pg_prove (if installed)
pg_prove -h localhost -d postgres tests/unit/
```

### With Coverage
```bash
# Enable coverage tracking
psql -h localhost -d postgres -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"

# Run tests
psql -f tests/unit/test_reconcilemupstream.sql

# Check coverage
psql -c "SELECT * FROM pg_stat_statements WHERE query LIKE '%reconcilemupstream%';"
```

---

## 📊 Test Quality Metrics

### Coverage Targets
- **Line Coverage:** 90%+ of procedure code executed
- **Branch Coverage:** 80%+ of conditional branches tested
- **Error Path Coverage:** 100% of error handlers tested

### Example Coverage Report
```
Procedure: reconcilemupstream
Total Lines: 250
Lines Covered: 235
Coverage: 94.0%

Branches: 15
Branches Covered: 13
Coverage: 86.7%

Error Paths: 8
Paths Tested: 8
Coverage: 100%

OVERALL: ✅ PASS (meets all targets)
```

---

## 🎯 Test Naming Convention

```
test_<procedure_name>.sql
```

Examples:
- `test_reconcilemupstream.sql`
- `test_addarc.sql`
- `test_getmaterialbyrunproperties.sql`

**Inside Each Test File:**
- Test 1: Happy Path
- Test 2: Error Handling
- Test 3: Edge Cases
- Test 4: Data Types
- Test 5: Transactions
- Test 6: Performance (basic)

---

## 🚀 Test Automation

### Pre-Commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run unit tests before commit
echo "Running unit tests..."
for test in tests/unit/test_*.sql; do
  if ! psql -h localhost -d postgres -f "$test" > /dev/null 2>&1; then
    echo "❌ Test failed: $test"
    exit 1
  fi
done

echo "✅ All unit tests passed"
```

### CI/CD Integration
```yaml
# .github/workflows/test.yml
name: Unit Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install pgTAP
        run: |
          sudo apt-get install -y postgresql-16-pgtap
      
      - name: Run Unit Tests
        run: |
          for test in tests/unit/test_*.sql; do
            psql -h localhost -U postgres -f "$test"
          done
```

---

## 📚 pgTAP Reference

### Common Assertions

```sql
-- Existence checks
SELECT has_table('schema', 'table_name', 'Table exists');
SELECT has_function('schema', 'function_name', 'Function exists');

-- Result checks
SELECT is(actual, expected, 'Values match');
SELECT isnt(actual, expected, 'Values differ');
SELECT ok(condition, 'Condition is true');

-- Result set checks
SELECT results_eq(
    'SELECT actual query',
    'SELECT expected query',
    'Result sets match'
);

SELECT bag_eq(
    'SELECT actual (any order)',
    'SELECT expected (any order)',
    'Result sets match (unordered)'
);

-- Exception checks
SELECT throws_ok(
    'SELECT query',
    'error_code',
    'error_message',
    'Throws expected error'
);

SELECT lives_ok(
    'SELECT query',
    'Executes without error'
);

-- Count checks
SELECT is(
    (SELECT COUNT(*) FROM table),
    expected_count,
    'Row count matches'
);
```

---

## 🔗 Related Documentation

- Integration tests: `/tests/integration/`
- Performance tests: `/tests/performance/`
- Test fixtures: `/tests/fixtures/`
- Test automation: `/scripts/automation/generate-tests.py`
- CI/CD: `/.github/workflows/test.yml`

---

## 🚨 Troubleshooting

### pgTAP Not Found
```bash
# Install pgTAP
sudo apt-get install postgresql-16-pgtap

# Or from source
git clone https://github.com/theory/pgtap.git
cd pgtap
make && sudo make install
```

### Test Fails in CI But Passes Locally
```bash
# Check PostgreSQL version
psql --version

# Check pgTAP version
psql -c "SELECT * FROM pg_extension WHERE extname = 'pgtap';"

# Run with verbose output
psql -f test.sql -v ON_ERROR_STOP=1
```

### Slow Tests
```bash
# Profile test execution
\timing on
\i tests/unit/test_procedure.sql

# Or use EXPLAIN ANALYZE
EXPLAIN ANALYZE SELECT * FROM procedure_name(...);
```

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)  
**Last Updated:** 2025-11-13  
**Version:** 1.0
