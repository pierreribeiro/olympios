# Validation Contracts: Migration Quality Assurance

**Created**: 2026-01-19
**Feature**: 001-tsql-to-pgsql
**Purpose**: Define acceptance criteria and validation methods for migrated database objects

---

## Overview

This document specifies the validation contracts that ALL migrated database objects must satisfy before deployment. These contracts ensure:

1. **Functional Correctness**: Output matches SQL Server exactly
2. **Performance Compliance**: Execution within 20% of baseline
3. **Data Integrity**: Zero data loss, complete row/column preservation
4. **Constitution Compliance**: All seven core principles followed
5. **Quality Standards**: ≥7.0/10 score (target ≥8.0/10)

---

## Contract 1: Functional Correctness

### Purpose
Verify that PostgreSQL objects produce identical results to SQL Server equivalents for the same inputs.

### Scope
Applies to: Views, Functions, Stored Procedures (already migrated)

### Acceptance Criteria

```typescript
interface FunctionalCorrectnessContract {
    // Input matching
    same_parameter_types: boolean;
    same_parameter_count: boolean;

    // Output matching
    same_column_count: boolean;
    same_column_names: boolean;
    same_column_types: boolean;
    same_row_count: boolean;
    same_row_values: boolean;
    same_row_order: boolean;  // If ORDER BY specified

    // Edge cases
    null_handling_identical: boolean;
    empty_set_behavior_identical: boolean;
    error_conditions_identical: boolean;

    // Overall
    functional_correctness_passed: boolean;
}
```

### Validation Method

**Test Case Structure**:
```sql
-- 1. Define test inputs
-- 2. Execute on SQL Server
-- 3. Execute on PostgreSQL
-- 4. Compare outputs

-- Example: McGetUpStream function
-- SQL Server
DECLARE @result1 TABLE (start_point VARCHAR(50), end_point VARCHAR(50), hop_count INT, path VARCHAR(MAX));
INSERT INTO @result1 EXEC McGetUpStream 'MATERIAL123';
SELECT * FROM @result1 ORDER BY start_point, hop_count;

-- PostgreSQL
SELECT * FROM mcgetupstream('MATERIAL123') ORDER BY start_point, hop_count;

-- Comparison
-- Expected: Identical row count, column values, order
```

**Automated Comparison Script**: `scripts/validation/compare-results.py`

```python
def validate_functional_correctness(sql_server_result, postgresql_result):
    """
    Compare SQL Server and PostgreSQL query results.

    Args:
        sql_server_result: pandas DataFrame from SQL Server
        postgresql_result: pandas DataFrame from PostgreSQL

    Returns:
        FunctionalCorrectnessReport with pass/fail + differences
    """
    assert sql_server_result.shape == postgresql_result.shape
    assert sql_server_result.columns.tolist() == postgresql_result.columns.tolist()
    assert sql_server_result.values == postgresql_result.values
```

### Test Data Requirements

**Coverage**:
- Normal cases (80% of tests)
- Edge cases (15% of tests): Empty inputs, NULL values, boundary conditions
- Error cases (5% of tests): Invalid inputs, constraint violations

**Data Sources**:
- Production sample data (anonymized if needed)
- Synthetic test data (generated)
- Edge case fixtures (manually crafted)

### Tolerance Thresholds

**Acceptable Differences**:
- Floating-point precision: ±0.0001
- Timestamp precision: ±1 second (if converting DATETIME → TIMESTAMP)
- String case: Exact match required (case-sensitive)

**Unacceptable Differences**:
- Row count mismatch
- Column count mismatch
- NULL vs non-NULL
- Data type incompatibility

### Pass/Fail Criteria

**PASS**: All assertions succeed, zero tolerance-exceeding differences
**FAIL**: Any assertion fails OR any unacceptable difference detected

---

## Contract 2: Performance Compliance

### Purpose
Ensure migrated objects execute within 20% of SQL Server baseline performance.

### Scope
Applies to: All objects (Views, Functions, Tables with Indexes)

### Acceptance Criteria

```typescript
interface PerformanceComplianceContract {
    // Baseline captured
    sql_server_baseline_captured: boolean;
    baseline_environment_documented: boolean;  // Data volume, hardware, etc.

    // PostgreSQL measurement
    postgresql_performance_measured: boolean;
    same_test_conditions: boolean;  // Same data volume, same queries

    // Comparison
    execution_time_degradation_percent: number;
    within_20_percent_threshold: boolean;

    // Query optimization
    indexes_utilized: boolean;
    sequential_scans_minimized: boolean;
    explain_plan_reviewed: boolean;

    // Overall
    performance_compliance_passed: boolean;
}
```

### Validation Method

**Baseline Capture (SQL Server)**:
```sql
-- Enable statistics
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- Execute query
EXEC McGetUpStream 'MATERIAL123';

-- Capture metrics:
-- - CPU time (ms)
-- - Elapsed time (ms)
-- - Logical reads
-- - Physical reads
```

**PostgreSQL Measurement**:
```sql
-- Explain with timing
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING ON)
SELECT * FROM mcgetupstream('MATERIAL123');

-- Capture metrics:
-- - Execution Time (ms)
-- - Planning Time (ms)
-- - Shared Hits (buffer hits)
-- - Shared Reads (disk reads)
```

**Automated Performance Test**: `scripts/validation/performance-test.sql`

```sql
CREATE FUNCTION run_performance_test(
    p_object_name TEXT,
    p_test_query TEXT,
    p_baseline_ms NUMERIC
) RETURNS TABLE (
    test_name TEXT,
    postgresql_ms NUMERIC,
    degradation_percent NUMERIC,
    passed BOOLEAN
) AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_ms NUMERIC;
    degradation NUMERIC;
BEGIN
    -- Run query 10 times, take median
    -- Compare to baseline
    -- Return results
END;
$$ LANGUAGE plpgsql;
```

### Performance Metrics

| Metric | SQL Server Source | PostgreSQL Source | Comparison |
|--------|-------------------|-------------------|------------|
| Execution Time | STATISTICS TIME (elapsed) | EXPLAIN ANALYZE (Execution Time) | Primary metric |
| I/O Operations | STATISTICS IO (logical reads) | EXPLAIN BUFFERS (Shared Hits/Reads) | Secondary metric |
| CPU Time | STATISTICS TIME (CPU time) | pg_stat_statements (total_time) | Secondary metric |

### Pass/Fail Criteria

**PASS**: `(postgresql_ms - baseline_ms) / baseline_ms * 100 <= 20%`

**FAIL**: Degradation > 20%

**Action on Failure**:
1. Review EXPLAIN plan for inefficiencies
2. Check index usage (sequential scans vs index scans)
3. Verify statistics are up to date (ANALYZE)
4. Tune PostgreSQL configuration (work_mem, shared_buffers)
5. Re-test after optimization

### Optimization Checklist

Before declaring performance failure:
- [ ] ANALYZE run on all tables
- [ ] Indexes created per design
- [ ] VACUUM run to remove dead tuples
- [ ] PostgreSQL configuration tuned (work_mem, effective_cache_size)
- [ ] Query plan reviewed (no unnecessary sequential scans)
- [ ] Predicate pushdown verified (for FDW queries)

---

## Contract 3: Data Integrity

### Purpose
Guarantee zero data loss during table migration with complete row and column preservation.

### Scope
Applies to: Tables (91 objects)

### Acceptance Criteria

```typescript
interface DataIntegrityContract {
    // Row-level checks
    row_count_match: boolean;
    all_rows_migrated: boolean;

    // Column-level checks
    column_count_match: boolean;
    column_names_match: boolean;
    column_types_compatible: boolean;

    // Value-level checks
    checksum_match: boolean;
    null_values_preserved: boolean;
    default_values_applied: boolean;

    // Constraint verification
    primary_keys_enforced: boolean;
    foreign_keys_enforced: boolean;
    unique_constraints_enforced: boolean;
    check_constraints_enforced: boolean;

    // Overall
    data_integrity_passed: boolean;
}
```

### Validation Method

**Row Count Validation**:
```sql
-- SQL Server
SELECT COUNT(*) AS row_count FROM perseus.dbo.goo;
-- Result: 45,123

-- PostgreSQL
SELECT COUNT(*) AS row_count FROM perseus_dbo.goo;
-- Expected: 45,123 (exact match)
```

**Checksum Validation**:
```sql
-- SQL Server
SELECT CHECKSUM_AGG(CHECKSUM(*)) AS table_checksum
FROM perseus.dbo.goo;
-- Result: 1234567890

-- PostgreSQL (equivalent)
SELECT SUM(hashtext(goo::TEXT)::BIGINT) AS table_checksum
FROM perseus_dbo.goo;
-- Expected: Consistent checksum (algorithm-dependent)
```

**Column Comparison**:
```sql
-- SQL Server
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'goo'
ORDER BY ORDINAL_POSITION;

-- PostgreSQL
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'goo'
ORDER BY ordinal_position;

-- Compare outputs (same columns, compatible types)
```

**Automated Data Integrity Check**: `scripts/validation/data-integrity-check.sql`

```sql
CREATE FUNCTION verify_table_migration(
    p_table_name TEXT,
    p_sql_server_row_count BIGINT,
    p_sql_server_checksum BIGINT
) RETURNS TABLE (
    table_name TEXT,
    row_count_match BOOLEAN,
    checksum_match BOOLEAN,
    passed BOOLEAN
) AS $$
BEGIN
    -- Verify row count
    -- Verify checksum
    -- Return results
END;
$$ LANGUAGE plpgsql;
```

### Data Type Compatibility Matrix

| SQL Server Type | PostgreSQL Type | Notes |
|-----------------|-----------------|-------|
| NVARCHAR(n) | VARCHAR(n) | UTF-8 encoding |
| MONEY | NUMERIC(19,4) | Precision preserved |
| UNIQUEIDENTIFIER | UUID | Direct mapping |
| DATETIME | TIMESTAMP | Subsecond precision |
| BIT | BOOLEAN | True/False mapping |
| IDENTITY(1,1) | GENERATED ALWAYS AS IDENTITY | Auto-increment |
| ROWVERSION | BIGINT + trigger | No direct equivalent |

### Constraint Violation Testing

**Purpose**: Verify constraints enforce same business rules

```sql
-- Test PRIMARY KEY
INSERT INTO goo (uid) VALUES ('DUPLICATE');
-- Expected: ERROR - duplicate key value violates unique constraint

-- Test FOREIGN KEY
INSERT INTO material_transition (transition_id) VALUES (999999);
-- Expected: ERROR - insert or update on table violates foreign key constraint

-- Test CHECK constraint
INSERT INTO goo (status) VALUES ('INVALID_STATUS');
-- Expected: ERROR - new row violates check constraint

-- Test UNIQUE constraint
INSERT INTO goo (barcode) VALUES ('EXISTING_BARCODE');
-- Expected: ERROR - duplicate key value violates unique constraint
```

### Pass/Fail Criteria

**PASS**: All criteria true:
- Row count exact match
- Checksum match (or acceptable algorithm difference documented)
- All columns present with compatible types
- All constraints enforce successfully

**FAIL**: Any criteria false

---

## Contract 4: Constitution Compliance

### Purpose
Verify all seven core principles of the PostgreSQL Programming Constitution are followed.

### Scope
Applies to: All code objects (Views, Functions, Procedures)

### Acceptance Criteria

```typescript
interface ConstitutionComplianceContract {
    principle_1_ansi_sql_primacy: boolean;       // Standard SQL, no vendor extensions
    principle_2_strict_typing: boolean;          // Explicit CAST/::
    principle_3_set_based_execution: boolean;    // No cursors, WHILE loops
    principle_4_atomic_transactions: boolean;    // Explicit BEGIN/COMMIT/ROLLBACK
    principle_5_idiomatic_naming: boolean;       // snake_case, no Hungarian
    principle_6_structured_errors: boolean;      // Specific exceptions
    principle_7_modular_logic: boolean;          // Schema-qualified, named params

    overall_constitution_compliance: boolean;
}
```

### Validation Method

**Principle I: ANSI-SQL Primacy**
```bash
# Check for SQL Server-specific syntax
grep -E 'NOLOCK|READPAST|ROWLOCK|UPDLOCK' refactored.sql
# Expected: No matches

# Check for PostgreSQL-specific syntax overuse
grep -E 'LATERAL|DISTINCT ON' refactored.sql
# Expected: Minimal usage (only where necessary)
```

**Principle II: Strict Typing**
```bash
# Check for implicit type coercion
grep -E '= [0-9]+\.[0-9]+' refactored.sql | grep -v 'CAST\|::'
# Expected: No matches (all numeric comparisons explicitly cast)
```

**Principle III: Set-Based Execution**
```bash
# Check for cursors
grep -E 'DECLARE.*CURSOR|FETCH|OPEN|CLOSE' refactored.sql
# Expected: No matches

# Check for WHILE loops
grep -E 'WHILE' refactored.sql
# Expected: No matches (use CTEs instead)
```

**Principle IV: Atomic Transactions**
```bash
# Check for explicit transaction control
grep -E 'BEGIN;|COMMIT;|ROLLBACK;' refactored.sql
# Expected: Transactions explicitly managed
```

**Principle V: Idiomatic Naming**
```bash
# Check for PascalCase (should be snake_case)
grep -E '[A-Z][a-z]+[A-Z]' refactored.sql | grep -v '-- '
# Expected: No matches

# Check for Hungarian notation
grep -E 'sp_|fn_|tbl_|vw_' refactored.sql
# Expected: No matches
```

**Principle VI: Structured Errors**
```bash
# Check for specific exception types
grep -E 'WHEN unique_violation|WHEN foreign_key_violation' refactored.sql
# Expected: Specific exceptions used

# Check for generic WHEN OTHERS overuse
grep -E 'WHEN OTHERS' refactored.sql
# Expected: Minimal usage (final catch-all only)
```

**Principle VII: Modular Logic**
```bash
# Check for schema-qualified references
grep -E 'FROM [a-z_]+' refactored.sql | grep -v '\.'
# Expected: No matches (all qualified with schema)

# Check for positional parameters (should be named)
grep -E '\$[0-9]+' refactored.sql
# Expected: No matches (named parameters only)
```

### Pass/Fail Criteria

**PASS**: All seven principles verified compliant
**FAIL**: Any principle violation without documented justification

**Justification Required For**:
- Necessary vendor-specific syntax (with explanation)
- Unavoidable complexity (with simpler alternative rejected reason)

---

## Contract 5: Quality Score

### Purpose
Ensure all migrated objects achieve minimum quality standards across five dimensions.

### Scope
Applies to: All code objects (Views, Functions, Procedures)

### Acceptance Criteria

```typescript
interface QualityScoreContract {
    syntax_correctness: number;      // 0-10 (weight: 20%)
    logic_preservation: number;      // 0-10 (weight: 30%)
    performance: number;             // 0-10 (weight: 20%)
    maintainability: number;         // 0-10 (weight: 15%)
    security: number;                // 0-10 (weight: 15%)

    overall_score: number;           // Weighted average

    // Thresholds
    overall_minimum: number;         // 7.0
    overall_target: number;          // 8.0
    dimension_minimum: number;       // 6.0 (no dimension below this)

    quality_score_passed: boolean;
}
```

### Scoring Rubric

#### Syntax Correctness (20%)

| Score | Criteria |
|-------|----------|
| 10 | Compiles without errors or warnings, follows PostgreSQL best practices |
| 8 | Compiles without errors, minor warnings acceptable |
| 6 | Compiles with workarounds, some syntax issues |
| 4 | Syntax errors, requires significant rework |
| 2 | Major syntax errors, not functional |
| 0 | Does not compile |

#### Logic Preservation (30%)

| Score | Criteria |
|-------|----------|
| 10 | 100% output match with SQL Server, all edge cases handled |
| 8 | 99% output match, minor edge case differences |
| 6 | 95% output match, some logic differences |
| 4 | 90% output match, significant logic gaps |
| 2 | <90% output match, major logic errors |
| 0 | Fundamentally different behavior |

#### Performance (20%)

| Score | Criteria |
|-------|----------|
| 10 | Better than SQL Server baseline |
| 8 | Within 10% of baseline |
| 6 | Within 20% of baseline (acceptable) |
| 4 | 20-50% degradation |
| 2 | 50-100% degradation |
| 0 | >100% degradation |

#### Maintainability (15%)

| Score | Criteria |
|-------|----------|
| 10 | Well-documented, clear logic, follows constitution, easy to understand |
| 8 | Documented, clear logic, mostly follows constitution |
| 6 | Minimal documentation, logic understandable, some constitution violations |
| 4 | Poor documentation, convoluted logic |
| 2 | Undocumented, difficult to understand |
| 0 | Unmaintainable code |

#### Security (15%)

| Score | Criteria |
|-------|----------|
| 10 | No security issues, follows all security best practices |
| 8 | No security issues, minor best practice deviations |
| 6 | Low-severity security concerns |
| 4 | Medium-severity security issues |
| 2 | High-severity security vulnerabilities |
| 0 | Critical security flaws |

### Calculation Example

```typescript
function calculateQualityScore(scores: {
    syntax: number,
    logic: number,
    performance: number,
    maintainability: number,
    security: number
}): number {
    return (
        scores.syntax * 0.20 +
        scores.logic * 0.30 +
        scores.performance * 0.20 +
        scores.maintainability * 0.15 +
        scores.security * 0.15
    );
}

// Example: McGetUpStream
const scores = {
    syntax: 9.0,          // Compiles cleanly
    logic: 9.0,           // 100% output match
    performance: 7.5,     // 19.9% degradation (within 20%)
    maintainability: 8.0, // Well-documented
    security: 7.5         // No issues, minor hardening possible
};

const overall = calculateQualityScore(scores);
// Result: 8.2/10 (exceeds 7.0 minimum, meets 8.0 target)
```

### Pass/Fail Criteria

**PASS**: `overall_score >= 7.0 AND all dimensions >= 6.0`
**FAIL**: `overall_score < 7.0 OR any dimension < 6.0`

**Target**: `overall_score >= 8.0` (aspirational, not blocking)

---

## Integration Testing Contract

### Purpose
Verify cross-object interactions work correctly after migration.

### Scope
Applies to: Multi-object workflows (e.g., view → function → procedure)

### Test Scenarios

**Scenario 1: Material Lineage Workflow**
```sql
-- Flow: translated view → mcgetupstream function → application query

-- 1. Insert test data into material_transition and transition_material
-- 2. Refresh translated materialized view
-- 3. Call mcgetupstream function
-- 4. Verify upstream lineage is correct
```

**Scenario 2: FDW Cross-Database Query**
```sql
-- Flow: Local table JOIN foreign table (hermes)

-- 1. Query local goo table
-- 2. JOIN with hermes.run via FDW
-- 3. Verify results match SQL Server linked server query
```

**Scenario 3: Batch Processing**
```sql
-- Flow: Temp table → mcgetupstreambylist → m_upstream update

-- 1. Create temp table with 10,000 UIDs
-- 2. Call mcgetupstreambylist
-- 3. Verify batch processing completes in <5 seconds
```

### Pass/Fail Criteria

**PASS**: All integration scenarios execute successfully with expected outputs
**FAIL**: Any scenario fails or times out

---

## Validation Summary Checklist

Before deploying any migrated object to production:

- [ ] **Functional Correctness**: Output matches SQL Server (100%)
- [ ] **Performance Compliance**: Execution within 20% baseline
- [ ] **Data Integrity**: Zero data loss, row/column/checksum match
- [ ] **Constitution Compliance**: All 7 principles verified
- [ ] **Quality Score**: ≥7.0/10 overall, all dimensions ≥6.0/10
- [ ] **Integration Testing**: Multi-object workflows validated
- [ ] **Code Review**: Technical lead + DBA approval
- [ ] **Documentation**: Migration notes, test results, performance metrics

---

**Status**: ✅ Validation contracts defined - Ready for implementation and testing
