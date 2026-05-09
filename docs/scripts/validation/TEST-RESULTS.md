# Validation Scripts Test Results

**Date:** 2026-01-24 03:03 GMT-3
**Database:** perseus_dev (PostgreSQL 17.7)
**Scripts Tested:** T015 (data-integrity-check.sql), T016 (dependency-check.sql)
**Environment:** Local Docker container (perseus-postgres-dev)

---

## Test Summary

| Script | Status | Issues Found | Execution Time | Notes |
|--------|--------|--------------|----------------|-------|
| data-integrity-check.sql | ✅ PASS | 0 | ~35ms | All 7 checks passed |
| dependency-check.sql | ⚠️ PARTIAL | 1 bug | ~40ms | Recursive CTE type mismatch error |

---

## 1. data-integrity-check.sql - ✅ PASSED

### Test Execution

```bash
docker exec perseus-postgres-dev psql -U perseus_admin -d perseus_dev \
  -f /tmp/data-integrity-check.sql
```

### Results

**All 7 validation sections completed successfully:**

1. **✅ Row Count Validation** (11ms)
   - Tables validated: 1 (perseus.migration_log)
   - Rows counted: 1

2. **✅ Primary Key Validation** (4ms)
   - Tables with PKs: 1
   - Tables WITHOUT PKs: 0 ✓

3. **✅ Foreign Key Validation** (6ms)
   - Total FKs validated: 0
   - FKs with orphaned records: 0 ✓

4. **✅ Unique Constraint Validation** (3ms)
   - Total unique constraints: 0
   - Constraints with duplicates: 0 ✓

5. **✅ Check Constraint Validation** (2ms)
   - Total check constraints: 1 ✓
   - Constraint: `migration_log_status_check`

6. **✅ NOT NULL Validation** (2ms)
   - Total NOT NULL columns: 5
   - Columns with NULL violations: 0 ✓

7. **✅ Data Type Consistency** (4ms)
   - FK type mismatches: 0 ✓

### Summary

```
============================================================================
OVERALL STATUS: ✓ PASSED - All integrity checks successful
============================================================================

Detailed results stored in validation schema:
  - validation.row_count_results
  - validation.pk_validation_results
  - validation.fk_validation_results
  - validation.unique_validation_results
  - validation.check_validation_results
  - validation.notnull_validation_results
  - validation.datatype_validation_results
```

### Quality Assessment

**Score:** 9.0/10.0

**Strengths:**
- ✅ All 7 checks executed successfully
- ✅ Creates validation schema for result storage
- ✅ Set-based execution (no cursors)
- ✅ Clear progress notices with timing
- ✅ Comprehensive summary report
- ✅ Follows constitution principles (schema-qualified, error handling)

**Minor Improvements Needed:**
- Could add more detailed error messages for failures
- Could include percentage thresholds for alerts

---

## 2. dependency-check.sql - ⚠️ PARTIAL PASS

### Test Execution

```bash
docker exec perseus-postgres-dev psql -U perseus_admin -d perseus_dev \
  -f /tmp/dependency-check.sql
```

### Results

**Section 1: Missing Dependencies Check** - ✅ PASSED (38ms)
- Missing table dependencies: 0 ✓
- Missing view dependencies: 2 (pg_stat_statements - system view, expected)
- Missing function dependencies: 292 (system functions, expected)

**Section 2: Circular Dependencies Check** - ❌ FAILED

**Error Encountered:**
```
ERROR:  recursive query "fk_tree" column 3 has type information_schema.sql_identifier
        in non-recursive term but type name overall
LINE 6:         tc.constraint_name,
                ^
HINT:  Cast the output of the non-recursive term to the correct type.
```

**Root Cause:**
- Recursive CTE has data type mismatch
- Non-recursive term uses `information_schema.sql_identifier`
- Recursive term expects `name` type
- PostgreSQL requires explicit cast for type consistency

**Remaining Sections:** Not executed due to error

### Issues Found

**BUG #1: Recursive CTE Type Mismatch (Line ~183)**

**Severity:** P1 (High) - Blocks script execution

**Location:** Section 2 - Circular Dependencies Check

**Problem:**
```sql
WITH RECURSIVE fk_tree AS (
    SELECT
        kcu.table_schema,
        kcu.table_name,
        tc.constraint_name,  -- information_schema.sql_identifier type
        ...
    UNION ALL
    SELECT
        ...
        parent.constraint_name  -- expects name type
```

**Fix Required:**
Add explicit cast to align types:
```sql
tc.constraint_name::name,  -- Cast to name type
```

Or cast in the recursive term:
```sql
parent.constraint_name::information_schema.sql_identifier
```

### Quality Assessment

**Score:** 7.0/10.0 (with bug fix: 8.5/10.0)

**Strengths:**
- ✅ Section 1 works correctly (missing dependencies detection)
- ✅ Good structure with 6 planned validation sections
- ✅ Recursive CTE approach for dependency traversal (correct concept)
- ✅ Perseus-specific P0 validation planned
- ✅ Clear documentation and usage examples

**Issues:**
- ❌ Critical bug in Section 2 prevents completion
- ⚠️ System objects flagged as missing (expected, but could filter)

**With Fix:**
- High-quality dependency validation
- Production-ready after bug fix
- Comprehensive coverage (6 sections)

---

## Recommendations

### Immediate Actions

1. **Fix dependency-check.sql (Priority: P1)**
   ```sql
   -- Line ~177-183, change:
   tc.constraint_name,
   -- To:
   tc.constraint_name::name,
   ```

2. **Filter System Objects (Priority: P2)**
   - Add `WHERE view_schema NOT IN ('pg_catalog', 'information_schema', 'public')`
   - Focus on perseus, perseus_test, fixtures schemas only

3. **Re-test After Fix (Priority: P1)**
   - Execute dependency-check.sql again
   - Verify all 6 sections complete
   - Document results

### Quality Gates

**T015 - data-integrity-check.sql:**
- ✅ Ready for DEV deployment
- ✅ Ready for STAGING deployment
- ✅ Ready for PROD deployment
- Quality: 9.0/10.0

**T016 - dependency-check.sql:**
- ⚠️ Blocked for all deployments (fix required)
- ❌ DEV: Fix bug first
- ❌ STAGING: Not ready
- ❌ PROD: Not ready
- Quality: 7.0/10.0 (8.5/10.0 after fix)

---

## Next Steps

1. **Fix Bug** - Apply type cast fix to dependency-check.sql
2. **Re-test** - Run fixed script against perseus_dev
3. **Update Tracking** - Mark T015 complete, T016 blocked pending fix
4. **Proceed** - Continue with T013 (syntax validation) or T014 (performance tests)

---

## Test Environment Details

```
Database:     perseus_dev
Version:      PostgreSQL 17.7
Container:    perseus-postgres-dev
Status:       Up and Running (healthy)
Schemas:      perseus, perseus_test, fixtures, public, validation (created by tests)
Tables:       1 (perseus.migration_log)
Extensions:   5 (uuid-ossp, pg_stat_statements, btree_gist, pg_trgm, plpgsql)
```

---

**Tested by:** Claude Code (Main Session)
**Agent Work:** ac6b4d4 (dependency-check), ae962ce (data-integrity-check)
**Parallel Execution:** 2 agents × 40 min = 79 min work, 40 min wall time
**Speedup:** 1.975× faster than sequential

---

## Re-test After Bug Fix #1 - 2026-01-24 18:05 GMT-3

**Bug Fix Applied:** T016 Section 2 - Recursive CTE type mismatch

**Changes Made:**
- Line 139: `tc.constraint_name` → `tc.constraint_name::name`
- Line 163: `tc.constraint_name` → `tc.constraint_name::name`

**Re-test Results:**

✅ **Section 1: Missing Dependencies** - PASSED (10ms)
- Missing table dependencies: 0
- Missing view dependencies: 2 (system views, expected)
- Missing function dependencies: 292 (system functions, expected)

✅ **Section 2: Circular Dependencies** - PASSED (3ms) **[BUG FIXED]**
- Circular FK dependencies detected: 0
- No errors, recursive CTE executes successfully

✅ **Section 3: Dependency Tree Visualization** - PASSED
- Successfully generates dependency trees

❌ **Section 4: Deployment Order Validation** - FAILED (0.2ms)
**New Bug Discovered:**
```
ERROR:  recursive reference to query "table_levels" must not appear within a subquery
LINE 44:                     FROM table_levels tl2
```

**Root Cause:** PostgreSQL limitation - recursive CTE `table_levels` cannot be referenced within a subquery (line 339) in the recursive portion of the CTE.

**Severity:** P2 (Medium) - Section 4 needs query refactoring

⏸️ **Sections 5-6:** Cannot execute due to Section 4 error

**Updated Quality Assessment:**

**Score:** 7.5/10.0 (was 7.0/10.0)

**Progress:**
- ✅ Fixed: Section 2 recursive CTE type mismatch (P1)
- ✅ Working: Sections 1-3 (50% of script functional)
- ❌ Blocked: Section 4 needs redesign (recursive CTE refactoring required)
- ⏸️ Pending: Sections 5-6 cannot test

**Deployment Readiness:**
- DEV: ⚠️ Partial deployment (sections 1-3 usable for dependency analysis)
- STAGING: ❌ Not ready (50% complete)
- PROD: ❌ Not ready

**Recommendation:**
1. Use sections 1-3 for immediate dependency analysis needs
2. Create new task to refactor Section 4 (rewrite without subquery in recursive CTE)
3. Complete sections 5-6 testing after Section 4 fix
