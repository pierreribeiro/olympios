# Quickstart Guide: T-SQL to PostgreSQL Migration

**Created**: 2026-01-19
**Feature**: 001-tsql-to-pgsql
**Audience**: Database Administrators, Migration Engineers
**Estimated Reading Time**: 15 minutes

---

## Overview

This guide provides a step-by-step walkthrough for migrating a single database object from SQL Server to PostgreSQL using the Perseus migration workflow. Follow this guide to understand the four-phase process before scaling to the full 91-table, 22-view, 25-function migration.

---

## Prerequisites

### Required Software

- **PostgreSQL 17** (target database)
- **SQL Server 2014+** (source database - read access)
- **AWS Schema Conversion Tool (SCT)** (for baseline conversion)
- **psql client** (for PostgreSQL command-line access)
- **Git** (for version control)
- **Python 3.8+** (for validation scripts)

### Required Access

- Read access to SQL Server Perseus database
- Write access to PostgreSQL DEV environment
- Access to dependency analysis documents (`docs/code-analysis/`)
- Git repository access (`sqlserver-to-postgresql-migration`)

### Knowledge Requirements

- SQL (both T-SQL and PL/pgSQL)
- Database migration concepts
- Git workflow
- Understanding of the [PostgreSQL Programming Constitution](/.specify/memory/constitution.md)

---

## Architecture Overview

```
┌─────────────────┐
│  SQL Server     │ (Read-Only)
│  Perseus DB     │
└────────┬────────┘
         │
         │ 1. Extract
         ▼
┌─────────────────┐
│  AWS SCT        │
│  Conversion     │
└────────┬────────┘
         │
         │ 2. Baseline (70% complete)
         ▼
┌─────────────────┐
│  Manual         │
│  Refactoring    │ (30% correction)
└────────┬────────┘
         │
         │ 3. Validation
         ▼
┌─────────────────┐
│  PostgreSQL 17  │
│  DEV/STAGING    │
└─────────────────┘
```

---

## The Four-Phase Workflow

```
Phase 1: Analysis
    │
    ├─→ Review AWS SCT output
    ├─→ Identify issues (P0/P1/P2)
    ├─→ Generate analysis document
    └─→ Quality score ≥6.0
         │
Phase 2: Refactoring
    │
    ├─→ Apply P0/P1 fixes
    ├─→ Constitution compliance
    ├─→ Code review
    └─→ Syntax validation
         │
Phase 3: Validation
    │
    ├─→ Unit tests
    ├─→ Performance tests
    ├─→ Data integrity checks
    └─→ Quality score ≥7.0
         │
Phase 4: Deployment
    │
    ├─→ Deploy to DEV
    ├─→ Deploy to STAGING
    ├─→ Smoke tests
    └─→ Deploy to PRODUCTION
```

---

## Example Walkthrough: Migrating the `translated` Materialized View

We'll use the **translated view** as our example - it's a P0 critical object that converts from SQL Server indexed view to PostgreSQL materialized view.

### Step 1: Extract Original T-SQL (5 minutes)

**Command**:
```bash
# Connect to SQL Server and extract view definition
sqlcmd -S sqlappsta -d Perseus -Q "SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.translated'))" -o source/original/sqlserver/translated.sql
```

**Output** (`source/original/sqlserver/translated.sql`):
```sql
CREATE VIEW [dbo].[translated]
WITH SCHEMABINDING
AS
SELECT
    mt.material_id AS source_material,
    tm.material_id AS destination_material,
    mt.transition_id
FROM dbo.material_transition AS mt
JOIN dbo.transition_material AS tm
    ON tm.transition_id = mt.transition_id;

CREATE UNIQUE CLUSTERED INDEX [ix_translated]
ON [dbo].[translated] (source_material, destination_material, transition_id);
```

**Checkpoint**: Original T-SQL saved to repository ✅

---

### Step 2: Run AWS SCT Conversion (10 minutes)

**Command**:
```bash
# Use AWS SCT GUI or CLI to convert
aws-sct-cli convert \
    --source sqlserver://sqlappsta/Perseus \
    --target postgresql://localhost:5432/perseus \
    --object "dbo.translated" \
    --output source/original/pgsql-aws-sct-converted/translated.sql
```

**Output** (`source/original/pgsql-aws-sct-converted/translated.sql`):
```sql
-- AWS SCT WARNING: MSSQL4091 - Indexed view not supported in PostgreSQL
CREATE OR REPLACE VIEW perseus.translated AS
SELECT
    mt.material_id AS source_material,
    tm.material_id AS destination_material,
    mt.transition_id
FROM perseus.material_transition AS mt
JOIN perseus.transition_material AS tm
    ON tm.transition_id = mt.transition_id;

-- Index creation commented out (not supported on views)
-- CREATE UNIQUE INDEX ix_translated ON perseus.translated (...);
```

**AWS SCT Warnings**:
- `MSSQL4091`: Indexed views not supported in PostgreSQL (convert to materialized view)

**Checkpoint**: AWS SCT baseline generated ✅

---

### Step 3: Phase 1 - Analysis (30 minutes)

**Load Dependency Information**:
```bash
# Read from dependency analysis
grep -A 10 "translated" docs/code-analysis/dependency-analysis-lote3-views.md
```

**Output**:
```markdown
### translated (P0 - CRITICAL)
- **Type**: Indexed view (WITH SCHEMABINDING)
- **Depends on**: material_transition, transition_material
- **Used by**: McGetUpStream, McGetDownStream, McGetUpStreamByList, McGetDownStreamByList, upstream, downstream
- **Conversion Strategy**: Materialized view with scheduled refresh
```

**Create Analysis Document** (`docs/code-analysis/views/translated-analysis.md`):

```markdown
# Analysis: translated View

## Summary
- **Object Type**: View (Indexed → Materialized)
- **Priority**: P0 (CRITICAL)
- **Complexity**: 8/10
- **AWS SCT Baseline**: 70% complete
- **Manual Work Required**: Convert to materialized view, add refresh strategy

## Issues Identified

### P0 Issues (Critical)
1. **MSSQL4091**: Indexed view not supported
   - **Fix**: Convert to `CREATE MATERIALIZED VIEW`
   - **Impact**: View will require explicit refresh (not auto-updated)

### P1 Issues (Performance)
1. **Missing refresh strategy**: Materialized view needs refresh mechanism
   - **Fix**: Implement pg_cron scheduled refresh (every 10 minutes)
   - **Impact**: Data will be eventually consistent (5-15 minute staleness acceptable)

2. **Missing CONCURRENTLY index**: Required for non-blocking refresh
   - **Fix**: Create UNIQUE index matching original clustered index
   - **Impact**: Allows queries during refresh operations

## Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Syntax Correctness | 7.0 | AWS SCT valid syntax, missing materialized view conversion |
| Logic Preservation | 10.0 | Query logic identical |
| Performance | 8.0 | Materialized view provides 10-100x speedup vs regular view |
| Maintainability | 9.0 | Simple SELECT, well-documented |
| Security | 8.0 | No security concerns |
| **Overall** | **8.4** | Exceeds 7.0 threshold |

## Corrected Code

See: `source/building/pgsql/refactored/views/translated.sql`
```

**Checkpoint**: Analysis complete, quality score 8.4/10 ✅

---

### Step 4: Phase 2 - Refactoring (45 minutes)

**Create Refactored Code** (`source/building/pgsql/refactored/views/translated.sql`):

```sql
-- ===================================================================
-- MATERIALIZED VIEW: translated
-- ===================================================================
-- Converted from: SQL Server indexed view
-- Conversion Tool: AWS SCT + Manual Review
-- Reviewed by: Pierre Ribeiro
-- Date: 2026-01-19
--
-- CHANGES FROM ORIGINAL:
-- 1. Converted from indexed view to materialized view
-- 2. Added UNIQUE index for CONCURRENTLY refresh support
-- 3. Scheduled pg_cron refresh job (every 10 minutes)
--
-- DEPENDENCIES:
-- - perseus.material_transition (table)
-- - perseus.transition_material (table)
--
-- REFRESH STRATEGY:
-- - Scheduled: pg_cron every 10 minutes
-- - Method: REFRESH MATERIALIZED VIEW CONCURRENTLY
-- - Cleanup: VACUUM ANALYZE after each refresh
-- ===================================================================

CREATE MATERIALIZED VIEW perseus.translated AS
SELECT
    mt.material_id AS source_material,
    tm.material_id AS destination_material,
    mt.transition_id
FROM perseus.material_transition AS mt
JOIN perseus.transition_material AS tm
    ON tm.transition_id = mt.transition_id;

-- REQUIRED: Unique index for CONCURRENTLY refresh
CREATE UNIQUE INDEX ix_translated_unique
ON perseus.translated (source_material, destination_material, transition_id);

-- Optional: Additional index matching SQL Server clustered index order
CREATE INDEX ix_translated_lookup
ON perseus.translated (destination_material, source_material, transition_id);

-- ===================================================================
-- REFRESH JOB (pg_cron)
-- ===================================================================
-- Install pg_cron extension first: CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule refresh every 10 minutes
SELECT cron.schedule(
    'refresh_translated_view',
    '*/10 * * * *',
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY perseus.translated$$
);

-- Schedule vacuum 5 minutes after refresh
SELECT cron.schedule(
    'vacuum_translated_view',
    '5,15,25,35,45,55 * * * *',
    $$VACUUM ANALYZE perseus.translated$$
);

-- ===================================================================
-- GRANTS
-- ===================================================================
GRANT SELECT ON perseus.translated TO perseus_app;

-- ===================================================================
-- DOCUMENTATION
-- ===================================================================
COMMENT ON MATERIALIZED VIEW perseus.translated IS
'Unified view of material lineage edges (parent→transition→child). '
'Converted from SQL Server indexed view. '
'Refreshed every 10 minutes via pg_cron.';
```

**Constitution Compliance Check**:
```bash
# Principle V: Naming convention (snake_case)
grep -E '[A-Z]' refactored/views/translated.sql | grep -v '-- ' | grep -v 'AS\|FROM\|SELECT\|CREATE'
# ✅ No matches

# Principle VII: Schema-qualified references
grep -E 'FROM [a-z_]+' refactored/views/translated.sql | grep -v '\.'
# ✅ No matches (all qualified)
```

**Syntax Validation**:
```bash
# Test syntax
psql -h localhost -U perseus_admin -d perseus_dev -f source/building/pgsql/refactored/views/translated.sql
# ✅ Materialized view created successfully
```

**Checkpoint**: Refactored code complete, syntax valid ✅

---

### Step 5: Phase 3 - Validation (60 minutes)

#### Unit Test: Result Set Comparison

**Test Script** (`tests/unit/views/test_translated.sql`):
```sql
-- ===================================================================
-- UNIT TEST: translated materialized view
-- ===================================================================

-- Setup: Insert test data
BEGIN;

INSERT INTO perseus.material_transition (material_id, transition_id)
VALUES ('MAT001', 'TRANS001'), ('MAT002', 'TRANS002');

INSERT INTO perseus.transition_material (transition_id, material_id)
VALUES ('TRANS001', 'MAT003'), ('TRANS002', 'MAT004');

-- Refresh materialized view
REFRESH MATERIALIZED VIEW perseus.translated;

-- Test 1: Row count
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM perseus.translated;
    ASSERT v_count = 2, 'Expected 2 rows, got ' || v_count;
    RAISE NOTICE 'TEST PASS: Row count = 2';
END;
$$;

-- Test 2: Expected values
DO $$
DECLARE
    v_source VARCHAR(50);
    v_dest VARCHAR(50);
BEGIN
    SELECT source_material, destination_material
    INTO v_source, v_dest
    FROM perseus.translated
    WHERE source_material = 'MAT001';

    ASSERT v_source = 'MAT001' AND v_dest = 'MAT003',
        'Expected MAT001→MAT003, got ' || v_source || '→' || v_dest;
    RAISE NOTICE 'TEST PASS: MAT001 → MAT003';
END;
$$;

-- Cleanup
ROLLBACK;
```

**Run Test**:
```bash
psql -h localhost -U perseus_admin -d perseus_dev -f tests/unit/views/test_translated.sql
# ✅ Both tests pass
```

#### Performance Test: Query Execution Time

**SQL Server Baseline**:
```sql
-- SQL Server
SET STATISTICS TIME ON;
SELECT * FROM dbo.translated WHERE source_material = 'MATERIAL123';
-- Result: CPU time = 15 ms, elapsed time = 18 ms
```

**PostgreSQL Measurement**:
```sql
-- PostgreSQL
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
SELECT * FROM perseus.translated WHERE source_material = 'MATERIAL123';

-- Result:
-- Index Scan using ix_translated_unique on translated (actual time=0.015..0.022 rows=5 loops=1)
-- Execution Time: 0.025 ms
```

**Performance Calculation**:
```
Degradation = (25μs - 18ms) / 18ms * 100 = -99.86% (FASTER!)
✅ Within 20% threshold (actually 1000x faster due to materialization)
```

**Checkpoint**: All tests pass, performance excellent ✅

---

### Step 6: Phase 4 - Deployment (30 minutes)

#### Deploy to DEV

```bash
# Deploy refactored code
psql -h devserver -U perseus_admin -d perseus_dev -f source/building/pgsql/refactored/views/translated.sql

# Run smoke tests
psql -h devserver -U perseus_admin -d perseus_dev -f tests/unit/views/test_translated.sql

# Verify refresh job
psql -h devserver -U postgres -d postgres -c "SELECT * FROM cron.job WHERE jobname LIKE '%translated%';"
```

**Output**:
```
✅ Materialized view created
✅ Indexes created
✅ pg_cron jobs scheduled
✅ Smoke tests pass
```

#### Deploy to STAGING

```bash
# Same process on staging
psql -h stagingserver -U perseus_admin -d perseus_staging -f source/building/pgsql/refactored/views/translated.sql

# Run full integration tests
psql -h stagingserver -U perseus_admin -d perseus_staging -f tests/integration/test_material_lineage_workflow.sql
```

**Output**:
```
✅ Integration tests pass
✅ FDW queries work
✅ McGetUpStream function uses translated view correctly
```

#### Production Deployment (Pending Approval)

**Rollback Procedure** (`scripts/deployment/rollback-translated.sql`):
```sql
-- Rollback script for translated view
DROP MATERIALIZED VIEW IF EXISTS perseus.translated CASCADE;
SELECT cron.unschedule('refresh_translated_view');
SELECT cron.unschedule('vacuum_translated_view');

-- Restore SQL Server access (if needed during 30-day rollback window)
-- [Connect to SQL Server instead]
```

**Checkpoint**: DEV and STAGING deployments successful ✅

---

## Migration Metrics Dashboard

After completing the `translated` view migration, track these metrics:

```
┌─────────────────────────────────────────────────────────┐
│ Object: translated (Materialized View)                  │
├─────────────────────────────────────────────────────────┤
│ Status:         ✅ DEPLOYED TO STAGING                  │
│ Phase:          4 (Deployment)                          │
│ Quality Score:  8.4/10                                  │
│ Performance:    +99.86% (1000x faster than baseline)    │
│ Tests Passed:   12/12 (100%)                            │
│ Issues Resolved: 2 P0, 1 P1                             │
│ Time Invested:  3 hours                                 │
└─────────────────────────────────────────────────────────┘
```

---

## Common Issues & Solutions

### Issue 1: "Materialized view must have at least one unique index"

**Error**:
```
ERROR: REFRESH MATERIALIZED VIEW CONCURRENTLY requires a unique index
```

**Solution**:
```sql
CREATE UNIQUE INDEX ix_myview_unique ON perseus.myview (column1, column2);
```

---

### Issue 2: AWS SCT adds excessive LOWER() calls

**Problem**: AWS SCT converts string comparisons to `LOWER(column) = LOWER(value)` unnecessarily

**Fix**:
```sql
-- AWS SCT output (WRONG - performance killer)
WHERE LOWER(mt.material_id) = LOWER('MATERIAL123')

-- Corrected (CORRECT)
WHERE mt.material_id = 'MATERIAL123'
```

**Impact**: 40% performance improvement by removing unnecessary LOWER()

---

### Issue 3: Temp table "already exists" error

**Error**:
```
ERROR: relation "temp_us_goo_uids" already exists
```

**Solution**: Add defensive cleanup
```sql
DROP TABLE IF EXISTS temp_us_goo_uids;
CREATE TEMPORARY TABLE temp_us_goo_uids (...) ON COMMIT DROP;
```

---

## Next Steps

Now that you've migrated one view, scale to the full migration:

1. **Week 1-2**: Migrate all 91 tables (schema + indexes + constraints)
2. **Week 3**: Migrate data for all tables (full load + validation)
3. **Week 4-5**: Migrate 22 views + 25 functions
4. **Week 6**: Configure FDW (hermes, sqlapps, deimeter)
5. **Week 7**: Configure SymmetricDS replication + migrate 7 jobs
6. **Week 8**: Final integration testing + production cutover

**Total Estimated Time**: 8 weeks

---

## Key Takeaways

1. **Four-Phase Workflow**: Analysis → Refactoring → Validation → Deployment
2. **Quality Gates**: Minimum 7.0/10 score at each phase
3. **Constitution Compliance**: All 7 principles mandatory
4. **Performance Threshold**: ≤20% degradation acceptable
5. **Rollback Capability**: Maintain for 30 days post-migration

---

## Resources

- **Full Specification**: [spec.md](spec.md)
- **Implementation Plan**: [plan.md](plan.md)
- **Research Findings**: [research.md](research.md)
- **Data Model**: [data-model.md](data-model.md)
- **Validation Contracts**: [contracts/validation-contracts.md](contracts/validation-contracts.md)
- **Constitution**: [.specify/memory/constitution.md](/.specify/memory/constitution.md)

---

**Status**: ✅ Ready to begin full-scale migration
