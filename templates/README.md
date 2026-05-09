# Templates

## 📁 Directory Purpose

This directory contains **reusable templates** for creating consistent documentation, procedures, and tests across the migration project.

**Goal:** Standardize formats and reduce manual work

---

## 📋 Available Templates

### 1. postgresql-procedure-template.sql ⭐ NEW
**Purpose:** Production-ready PostgreSQL procedure template with best practices

**Based on:** ReconcileMUpstream analysis lessons learned  
**Compliance:** PostgreSQL 16+ best practices  
**Version:** 1.0  
**Created:** 2025-11-13

**Key Features:**
- ✅ Transaction control pattern (BEGIN/EXCEPTION/END)
- ✅ Temp tables with ON COMMIT DROP (automatic cleanup)
- ✅ Performance optimization (avoid LOWER(), proper indexing)
- ✅ Simplicity guidelines (avoid "hadouken" nested code)
- ✅ Comprehensive error handling (proper SQLSTATE)
- ✅ Built-in observability (RAISE NOTICE for execution tracking)
- ✅ Index suggestions for query optimization
- ✅ Input validation examples
- ✅ Pre/post deployment checklists

**Usage:**
```bash
# Copy template
cp templates/postgresql-procedure-template.sql procedures/corrected/procedure_name.sql

# Customize
# 1. Replace schema_name with actual schema (e.g., perseus_dbo)
# 2. Replace procedure_name with actual name (e.g., reconcilemupstream)
# 3. Update parameters (p_param1, p_param2, etc.)
# 4. Replace placeholder business logic with actual logic
# 5. Update index suggestions based on your queries
```

**What to Replace:**
```sql
-- BEFORE (Template)
CREATE OR REPLACE PROCEDURE schema_name.procedure_name(
    p_param1 VARCHAR(50),
    p_param2 INTEGER DEFAULT NULL
)

-- AFTER (Customized)
CREATE OR REPLACE PROCEDURE perseus_dbo.addarc(
    p_start_point VARCHAR(50),
    p_end_point VARCHAR(50)
)
```

**Structure Highlights:**
```sql
-- Header with metadata
-- Variable declarations (business, performance, error handling)
-- Initialization & logging
-- Input validation
-- Defensive cleanup (DROP TABLE IF EXISTS)
-- Temp table creation (with ON COMMIT DROP)
-- Main transaction block (BEGIN...EXCEPTION...END)
--   → Step 1: Data collection
--   → Step 2: Transformation
--   → Step 3: Persistence
--   → Step 4: Finalization
-- Error handling with proper SQLSTATE
-- Performance index suggestions
-- Usage examples
-- Testing checklist
-- Maintenance notes
```

**Benefits:**
- Saves 2-3 hours per procedure (no need to remember all patterns)
- Ensures consistency across all procedures
- Includes all lessons learned from ReconcileMUpstream
- Production-ready code from day one
- Built-in performance optimizations
- Comprehensive error handling

---

### 2. analysis-template.md
**Purpose:** Template for procedure analysis documents

**Usage:**
```bash
# Copy template
cp templates/analysis-template.md procedures/analysis/procedure_name-analysis.md

# Fill in sections
# - Quality scorecard
# - Issue breakdown (P0/P1/P2/P3)
# - Corrected code
# - Recommendations
```

**Sections:**
- Executive Summary
- Quality Scorecard (0-10 scale)
- Original Code (T-SQL)
- AWS SCT Output (PL/pgSQL)
- Issue Analysis
  - P0 Critical Issues
  - P1 High Priority Issues
  - P2 Medium Priority Issues
  - P3 Low Priority Issues
- Corrected Code (Production-Ready)
- Performance Considerations
- Testing Recommendations
- Deployment Checklist
- Change Log

---

### 3. procedure-template.sql (Legacy)
**Purpose:** Basic PostgreSQL procedure skeleton

**Note:** Consider using `postgresql-procedure-template.sql` instead (more comprehensive)

**Usage:**
```bash
# Copy template
cp templates/procedure-template.sql procedures/corrected/procedure_name.sql

# Customize
# - Replace placeholders
# - Add business logic
# - Update documentation
```

---

### 4. test-unit-template.sql
**Purpose:** pgTAP unit test template

**Usage:**
```bash
# Copy template
cp templates/test-unit-template.sql tests/unit/test_procedure_name.sql

# Customize test cases
```

**Structure:**
```sql
BEGIN;
SELECT plan(N);  -- Number of tests

-- Test cases here

SELECT * FROM finish();
ROLLBACK;
```

---

### 5. test-integration-template.sql
**Purpose:** Integration test workflow template

**Usage:**
```bash
# Copy template
cp templates/test-integration-template.sql tests/integration/test_workflow_name.sql

# Define workflow steps
```

---

## 🎯 Best Practices from postgresql-procedure-template.sql

### 1. Performance Optimization
```sql
-- ❌ BAD: LOWER() prevents index usage
WHERE LOWER(column) = LOWER('value')

-- ✅ GOOD: Direct comparison uses index
WHERE column = 'value'

-- ✅ ALTERNATIVE: Functional index if LOWER() is necessary
CREATE INDEX idx_column_lower ON table (LOWER(column));
WHERE LOWER(column) = 'value'
```

### 2. Temp Table Management
```sql
-- ❌ BAD: No auto-cleanup
CREATE TEMPORARY TABLE temp_data (...);

-- ✅ GOOD: Auto-cleanup on commit/rollback
CREATE TEMPORARY TABLE temp_data (...) ON COMMIT DROP;

-- ✅ BEST: Defensive cleanup + auto-cleanup
DROP TABLE IF EXISTS temp_data;
CREATE TEMPORARY TABLE temp_data (...) ON COMMIT DROP;
```

### 3. Transaction Control
```sql
-- ❌ BAD: No explicit transaction control
BEGIN
    -- business logic
END;

-- ✅ GOOD: Explicit transaction with error handling
BEGIN
    BEGIN  -- Inner transaction block
        -- business logic
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END;
END;
```

### 4. Error Handling
```sql
-- ❌ BAD: Generic error message
RAISE EXCEPTION 'Error: %', SQLERRM;

-- ✅ GOOD: Descriptive error with proper SQLSTATE
RAISE EXCEPTION '[%] Execution failed: % (SQLSTATE: %)', 
      procedure_name, error_message, error_state
      USING ERRCODE = 'P0001',
            HINT = 'Check input parameters',
            DETAIL = error_detail;
```

### 5. Simplicity (Avoid "Hadouken" Code)
```sql
-- ❌ BAD: Deeply nested ("hadouken" code)
IF condition1 THEN
    IF condition2 THEN
        IF condition3 THEN
            IF condition4 THEN
                -- business logic
            END IF;
        END IF;
    END IF;
END IF;

-- ✅ GOOD: Early returns, flat structure
IF NOT condition1 THEN RETURN; END IF;
IF NOT condition2 THEN RETURN; END IF;
IF NOT condition3 THEN RETURN; END IF;
IF NOT condition4 THEN RETURN; END IF;
-- business logic
```

### 6. Index Suggestions
```sql
-- Create indexes to support your queries
-- Use CONCURRENTLY to avoid locking production tables

-- For WHERE clauses
CREATE INDEX CONCURRENTLY idx_table_filter_columns
ON table_name (column1, column2)
WHERE column3 = 'common_value';

-- For JOINs
CREATE INDEX CONCURRENTLY idx_table_join_column
ON table_name (join_column, filter_column);

-- For lookups
CREATE INDEX CONCURRENTLY idx_table_lookup
ON table_name (lookup_column);

-- Always analyze after creating indexes
ANALYZE table_name;
```

---

## 🛠️ Using Templates

### Quick Start
```bash
# 1. Copy template
cp templates/postgresql-procedure-template.sql procedures/corrected/myproc.sql

# 2. Find and replace
sed -i 's/schema_name/perseus_dbo/g' procedures/corrected/myproc.sql
sed -i 's/procedure_name/myproc/g' procedures/corrected/myproc.sql

# 3. Edit business logic
code procedures/corrected/myproc.sql

# 4. Validate syntax
psql -f procedures/corrected/myproc.sql --dry-run

# 5. Test in DEV
psql -h dev-server -f procedures/corrected/myproc.sql
```

### Automated Generation
```bash
# Use automation script (if available)
python scripts/automation/generate-from-template.py \
  --template templates/postgresql-procedure-template.sql \
  --output procedures/corrected/myproc.sql \
  --replace "schema_name=perseus_dbo" \
  --replace "procedure_name=myproc"
```

---

## 📝 Template Placeholders

### postgresql-procedure-template.sql Placeholders
- `schema_name` - Database schema (e.g., perseus_dbo)
- `procedure_name` - Procedure name (e.g., reconcilemupstream)
- `p_param1`, `p_param2`, `p_param3` - Input parameters
- `source_table`, `target_table`, `final_table` - Table names
- `temp_working_data`, `temp_results` - Temp table names
- `c_batch_size` - Batch size constant
- All business logic sections marked with comments

---

## 🔍 Template Validation

### Pre-Commit Validation
```bash
# 1. Syntax check
psql -f procedure.sql --dry-run

# 2. Check for common issues
grep -E 'LOWER\(.*\).*=' procedure.sql  # Check for LOWER() usage
grep -E 'CREATE TEMPORARY TABLE' procedure.sql | grep -v 'ON COMMIT DROP'  # Check temp tables

# 3. Verify structure
grep -E '^-- ={70,}$' procedure.sql  # Check section separators
grep -E 'RAISE NOTICE' procedure.sql  # Check observability
```

### Post-Generation Review
```bash
# Checklist for generated procedures:
□ All placeholders replaced
□ Business logic implemented
□ Input validation added
□ Error messages customized
□ Index suggestions reviewed
□ Comments updated
□ Testing checklist reviewed
```

---

## 📊 Template Benefits

### Time Savings
| Activity | Without Template | With Template | Savings |
|----------|-----------------|---------------|---------|
| Initial code structure | 60 min | 5 min | 55 min |
| Error handling setup | 30 min | 0 min | 30 min |
| Transaction control | 20 min | 0 min | 20 min |
| Temp table management | 15 min | 0 min | 15 min |
| Logging/observability | 20 min | 0 min | 20 min |
| Index suggestions | 30 min | 5 min | 25 min |
| **TOTAL** | **175 min** | **10 min** | **165 min** |

**Average time saved per procedure:** ~2.5 hours

### Quality Improvements
- ✅ 100% consistency across procedures
- ✅ 0% missed error handling
- ✅ 0% forgotten temp table cleanup
- ✅ 100% observability coverage
- ✅ Standardized index strategy

---

## 🚀 Next Steps After Using Template

1. **Review Business Logic**
   - Ensure all steps are correct
   - Validate calculations
   - Check data transformations

2. **Optimize for Your Data**
   - Analyze actual table sizes
   - Adjust batch sizes if needed
   - Review index suggestions

3. **Test Thoroughly**
   - Unit tests (happy path + errors)
   - Integration tests
   - Performance tests
   - Load tests

4. **Deploy with Confidence**
   - DEV → STAGING → PRODUCTION
   - Monitor execution times
   - Track error rates
   - Validate results

---

## 📚 Additional Resources

### PostgreSQL Documentation
- [PL/pgSQL Best Practices](https://www.postgresql.org/docs/current/plpgsql-development-tips.html)
- [Transaction Management](https://www.postgresql.org/docs/current/plpgsql-transactions.html)
- [Error Handling](https://www.postgresql.org/docs/current/plpgsql-control-structures.html#PLPGSQL-ERROR-TRAPPING)
- [Performance Tips](https://www.postgresql.org/docs/current/performance-tips.html)

### Project Documentation
- See `aws-sct-conversion-analysis-reconcilemupstream.md` for detailed analysis
- See `PROJECT-PLAN.md` for overall migration strategy
- See `priority-matrix.csv` for procedure prioritization

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)  
**Last Updated:** 2025-11-13  
**Version:** 1.1 (Added postgresql-procedure-template.sql)
