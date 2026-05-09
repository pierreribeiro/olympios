# Quality Score Methodology

**Version:** 1.0
**Last Updated:** 2026-01-25
**Author:** Perseus Migration Project
**Status:** Active

---

## Overview

This document defines the standardized methodology for calculating quality scores across all migrated database objects in the Perseus SQL Server → PostgreSQL migration project. The quality score framework ensures consistent, objective assessment of 769 database objects with zero-defect requirements and systematic validation.

**Purpose:**
- Provide objective, repeatable quality assessment
- Ensure constitutional compliance (7 core principles)
- Enable data-driven deployment decisions
- Track quality trends across the migration lifecycle

**Scope:**
- All database objects: procedures (15), functions (25), views (22), tables (91), indexes (352), constraints (271)
- All migration phases: DEV → STAGING → PROD
- All quality dimensions: syntax, logic, performance, maintainability, security

---

## Scoring Framework

The quality score framework evaluates database objects across **5 dimensions** with weighted contributions to an **overall score from 0.0 to 10.0**.

| Dimension | Weight | Focus Area |
|-----------|--------|------------|
| **Syntax Correctness** | 20% | Valid PostgreSQL 17 syntax |
| **Logic Preservation** | 30% | Business logic identical to SQL Server |
| **Performance** | 20% | Within ±20% of SQL Server baseline |
| **Maintainability** | 15% | Readable, documented, constitution-compliant |
| **Security** | 15% | No vulnerabilities, proper permissions |

**Overall Score Formula:**
```
Overall Score = (Syntax × 0.20) + (Logic × 0.30) + (Performance × 0.20)
                + (Maintainability × 0.15) + (Security × 0.15)
```

---

## Dimension 1: Syntax Correctness (20% weight)

### Definition
Valid PostgreSQL 17 syntax that compiles without errors and follows PostgreSQL idioms.

### Scoring Rubric

| Score | Description | Criteria |
|-------|-------------|----------|
| **10.0** | Perfect syntax | Zero errors, all PostgreSQL 17 idioms, optimal syntax choices |
| **9.0** | Excellent | Minor style issues (e.g., inconsistent quoting, non-optimal but valid syntax) |
| **8.0** | Good | Deprecated syntax but functional, compiles without errors |
| **7.0** | Acceptable | Compiles with warnings (non-blocking) |
| **6.0** | Marginal | Minor syntax errors (easily fixable, single-digit error count) |
| **<6.0** | Failed | Major syntax errors, does not compile (FAIL) |

### Validation Method

```bash
# Automated syntax validation
./scripts/validation/syntax-check.sh <file>.sql

# Manual validation
psql -d perseus_dev -f <file>.sql

# Expected output: No errors, zero warnings for 10.0 score
```

### Compliance Checklist

- [ ] No syntax errors (`ERROR:` in psql output)
- [ ] No syntax warnings (`WARNING:` in psql output)
- [ ] Uses PostgreSQL 17 idioms (not deprecated syntax)
- [ ] Proper use of `::type` or `CAST(x AS type)` for explicit casting
- [ ] Schema-qualified references (e.g., `perseus.material`)
- [ ] Correct temporary table syntax (`CREATE TEMPORARY TABLE ... ON COMMIT DROP`)
- [ ] Proper CTE syntax (`WITH ... AS (...)`)
- [ ] Correct transaction syntax (`BEGIN/COMMIT/ROLLBACK`)

### Examples

**GOOD (10.0):**
```sql
-- Perfect PostgreSQL 17 syntax
CREATE OR REPLACE FUNCTION perseus.get_material_by_id(
    material_id_ INTEGER
) RETURNS TABLE(material_name TEXT, created_at TIMESTAMPTZ)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.material_name::TEXT,
        m.created_at
    FROM perseus.material m
    WHERE m.material_id = material_id_;
END;
$$;
```

**ACCEPTABLE (8.0):**
```sql
-- Uses deprecated SERIAL instead of GENERATED ALWAYS AS IDENTITY
CREATE TABLE perseus.temp_table (
    id SERIAL PRIMARY KEY,  -- Deprecated but functional
    name TEXT NOT NULL
);
```

**FAILED (<6.0):**
```sql
-- SQL Server syntax, not PostgreSQL
CREATE PROCEDURE perseus.get_material
    @material_id INT  -- Invalid parameter syntax for PostgreSQL
AS
BEGIN
    SELECT * FROM material WHERE material_id = @material_id;
END;
```

### Common Issues and Deductions

| Issue | Score Deduction | Fix |
|-------|----------------|-----|
| Missing schema qualification | -0.5 | Add schema prefix (e.g., `perseus.material`) |
| Implicit casting | -0.5 | Use `CAST()` or `::type` |
| SQL Server syntax remnants | -2.0 to -5.0 | Convert to PostgreSQL syntax |
| Deprecated `SERIAL` instead of `GENERATED ALWAYS AS IDENTITY` | -1.0 | Use modern syntax |
| Missing `ON COMMIT DROP` for temp tables | -0.5 | Add proper cleanup behavior |

---

## Dimension 2: Logic Preservation (30% weight)

### Definition
Business logic functionally equivalent to SQL Server original, with identical result sets for all valid inputs and edge cases.

### Scoring Rubric

| Score | Description | Criteria |
|-------|-------------|----------|
| **10.0** | Perfect preservation | 100% logic preserved, all edge cases handled, identical behavior |
| **9.0** | Excellent | Logic preserved, minor non-functional differences (e.g., output formatting) |
| **8.0** | Good | Logic preserved, missing 1-2 non-critical edge cases |
| **7.0** | Acceptable | Core logic preserved, some edge cases missing (documented) |
| **6.0** | Marginal | Logic mostly preserved, missing important scenarios (requires fixes) |
| **<6.0** | Failed | Logic broken or incomplete (FAIL) |

### Validation Method

```sql
-- Compare result sets between SQL Server and PostgreSQL
-- SQL Server baseline
SELECT * FROM sqlserver_results;

-- PostgreSQL migrated
SELECT * FROM postgresql_results;

-- Difference check (should return 0 rows)
SELECT * FROM sqlserver_results EXCEPT SELECT * FROM postgresql_results;
SELECT * FROM postgresql_results EXCEPT SELECT * FROM sqlserver_results;
```

```bash
# Unit testing
psql -d perseus_dev -f tests/unit/test_<object>.sql

# Expected output: All assertions pass
```

### Compliance Checklist

- [ ] Result sets identical for all test cases
- [ ] NULL handling consistent
- [ ] Error handling equivalent
- [ ] Edge cases covered (empty inputs, boundary values, invalid inputs)
- [ ] Transaction behavior consistent
- [ ] Side effects identical (inserts, updates, deletes)
- [ ] Return values match (procedures, functions)

### Examples

**PERFECT (10.0):**
```sql
-- SQL Server Original
CREATE PROCEDURE dbo.AddArc
    @FromNodeId INT,
    @ToNodeId INT
AS
BEGIN
    IF @FromNodeId IS NULL OR @ToNodeId IS NULL
        RAISERROR('Node IDs cannot be NULL', 16, 1);

    INSERT INTO arc (from_node_id, to_node_id)
    VALUES (@FromNodeId, @ToNodeId);
END;

-- PostgreSQL Migrated (100% logic preserved)
CREATE OR REPLACE PROCEDURE perseus.addarc(
    from_node_id_ INTEGER,
    to_node_id_ INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF from_node_id_ IS NULL OR to_node_id_ IS NULL THEN
        RAISE EXCEPTION 'Node IDs cannot be NULL'
            USING HINT = 'Provide valid integer values for both node IDs';
    END IF;

    INSERT INTO perseus.arc (from_node_id, to_node_id)
    VALUES (from_node_id_, to_node_id_);
END;
$$;
```

**ACCEPTABLE (7.0):**
```sql
-- Missing edge case: does not handle duplicate arc insertion
-- Core logic preserved, but missing constraint validation
CREATE OR REPLACE PROCEDURE perseus.addarc(
    from_node_id_ INTEGER,
    to_node_id_ INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Missing: Check for duplicate arcs before insertion
    INSERT INTO perseus.arc (from_node_id, to_node_id)
    VALUES (from_node_id_, to_node_id_);
END;
$$;
```

**FAILED (<6.0):**
```sql
-- Logic broken: inserts in wrong order, missing transaction
CREATE OR REPLACE PROCEDURE perseus.addarc(
    from_node_id_ INTEGER,
    to_node_id_ INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- WRONG: Inserts to_node before from_node (logic error)
    INSERT INTO perseus.arc (from_node_id, to_node_id)
    VALUES (to_node_id_, from_node_id_);  -- Swapped parameters!
END;
$$;
```

### Common Issues and Deductions

| Issue | Score Deduction | Fix |
|-------|----------------|-----|
| Missing NULL handling | -1.0 | Add NULL checks with `RAISE EXCEPTION` |
| Missing edge cases (1-2) | -1.0 to -2.0 | Add validation for boundary conditions |
| Incorrect error handling | -2.0 | Match SQL Server error behavior |
| Swapped parameters/logic | -4.0 to -5.0 | Fix parameter order, verify logic |
| Missing transaction boundaries | -1.0 | Add explicit `BEGIN/COMMIT/ROLLBACK` |

---

## Dimension 3: Performance (20% weight)

### Definition
Query performance within ±20% of SQL Server baseline execution time (per Article III: Set-Based Execution).

### Scoring Rubric

| Score | Description | Performance Delta |
|-------|-------------|------------------|
| **10.0** | Excellent improvement | >20% faster than SQL Server |
| **9.0** | Good improvement | 10-20% faster |
| **8.0** | Equivalent | Within ±10% |
| **7.0** | Acceptable slowdown | 10-20% slower (within tolerance) |
| **6.0** | Marginal | 20-30% slower (marginal, requires investigation) |
| **<6.0** | Failed | >30% slower (FAIL) |

### Validation Method

```sql
-- Capture baseline
CALL performance.capture_baseline(
    'procedure',
    'perseus.addarc',
    'SELECT 1 WHERE EXISTS (SELECT 1 FROM perseus.arc WHERE arc_id = 1)',
    'dev',
    'Initial baseline capture'
);

-- Run performance test
CALL performance.run_performance_test(
    gen_random_uuid(),
    'procedure',
    'perseus.addarc',
    'SELECT 1 WHERE EXISTS (SELECT 1 FROM perseus.arc WHERE arc_id = 1)',
    'dev',
    v_status,
    v_delta,
    v_error
);

-- View results
SELECT * FROM performance.v_regression_summary
WHERE object_name = 'perseus.addarc';
```

### Performance Metrics

| Metric | Description | Threshold |
|--------|-------------|-----------|
| **Execution Time** | Total query execution time | ±20% of baseline |
| **Planning Time** | Query planning overhead | <10% of execution time |
| **Rows Returned** | Result set size | Identical to SQL Server |
| **Buffer Hit Ratio** | Shared buffer efficiency | >95% for cached queries |
| **I/O Operations** | Disk reads/writes | ±30% of baseline |

### Compliance Checklist

- [ ] Execution time within ±20% of SQL Server baseline
- [ ] No WHILE loops or cursors (Article III: Set-Based Execution)
- [ ] Uses CTEs and window functions for iteration
- [ ] Proper indexes utilized (verify with `EXPLAIN ANALYZE`)
- [ ] Buffer hit ratio >95% for cached queries
- [ ] Planning time <10% of execution time

### Examples

**EXCELLENT (10.0):**
```
SQL Server Baseline: 120ms
PostgreSQL Result:    50ms
Delta: -58.3% (58% faster) ✅ EXCELLENT
```

**ACCEPTABLE (7.0):**
```
SQL Server Baseline: 100ms
PostgreSQL Result:   115ms
Delta: +15.0% (15% slower) ✅ ACCEPTABLE (within ±20% tolerance)
```

**FAILED (<6.0):**
```
SQL Server Baseline: 80ms
PostgreSQL Result:  120ms
Delta: +50.0% (50% slower) ❌ FAILED (exceeds ±20% tolerance)
```

### EXPLAIN ANALYZE Example

```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT * FROM perseus.material WHERE material_id = 12345;

-- Good performance indicators:
-- ✅ Index Scan (not Seq Scan)
-- ✅ Execution time: 1.234ms (fast)
-- ✅ Buffers: shared hit=5 read=0 (100% cache hit)
-- ✅ Planning time: 0.123ms (<10% of execution)
```

### Common Issues and Deductions

| Issue | Score Deduction | Fix |
|-------|----------------|-----|
| Uses WHILE loop instead of CTE | -3.0 to -5.0 | Refactor to set-based query (CRITICAL) |
| Uses cursor instead of bulk operation | -3.0 to -5.0 | Refactor to set-based query (CRITICAL) |
| Sequential scan on large table | -1.0 to -2.0 | Add index |
| Low buffer hit ratio (<80%) | -0.5 to -1.0 | Optimize query, add indexes |
| Execution time 20-30% slower | -2.0 | Investigate query plan |
| Execution time >30% slower | -4.0 or FAIL | Major optimization required |

---

## Dimension 4: Maintainability (15% weight)

### Definition
Code readability, documentation quality, and compliance with the 7 core principles from the PostgreSQL Programming Constitution.

### Scoring Rubric

| Score | Description | Criteria |
|-------|-------------|----------|
| **10.0** | Exemplary | Clear, well-documented, 100% constitution compliance |
| **9.0** | Very good | Clear, some comments, constitution 95%+ |
| **8.0** | Good | Readable, constitution 90%+ |
| **7.0** | Adequate | Understandable, constitution 80%+ |
| **6.0** | Marginal | Hard to read, constitution 70%+ |
| **<6.0** | Poor | Unreadable or constitution <70% (FAIL) |

### Validation Method

```bash
# Constitution compliance analysis
python3 scripts/automation/analyze-object.py procedure addarc

# Expected output: Constitution compliance percentage
# Target: ≥90% for 8.0+ score
```

### Constitution Compliance Framework

The **7 Core Principles** (from `.specify/memory/constitution.md`):

| Article | Principle | Weight |
|---------|-----------|--------|
| **I** | **ANSI-SQL Primacy** | 15% |
| **II** | **Strict Typing & Explicit Casting** | 15% |
| **III** | **Set-Based Execution** (NON-NEGOTIABLE) | 20% |
| **IV** | **Atomic Transaction Management** | 15% |
| **V** | **Idiomatic Naming & Scoping** | 10% |
| **VI** | **Structured Error Resilience** | 15% |
| **VII** | **Modular Logic Separation** | 10% |

**Constitution Compliance Formula:**
```
Constitution Compliance % = (Sum of Article Scores) / 7 × 100%
```

### Compliance Checklist

#### Article I: ANSI-SQL Primacy (15%)
- [ ] Standard SQL over vendor extensions
- [ ] Portable logic (no PostgreSQL-only features unless necessary)
- [ ] Standard syntax for transactions, CTEs, window functions

#### Article II: Strict Typing & Explicit Casting (15%)
- [ ] All casts use `CAST(x AS type)` or `x::type`
- [ ] No implicit type coercion
- [ ] Proper data type selection (BIGINT for PKs, TIMESTAMPTZ for timestamps)

#### Article III: Set-Based Execution (20% - NON-NEGOTIABLE)
- [ ] **Zero WHILE loops** (use CTEs, recursive CTEs, or window functions)
- [ ] **Zero cursors** (use set-based queries)
- [ ] All iteration via set-based operations
- [ ] Window functions for ranking, aggregation

#### Article IV: Atomic Transaction Management (15%)
- [ ] Explicit `BEGIN/COMMIT/ROLLBACK`
- [ ] Transactions <10 minutes (timeout protection)
- [ ] Proper exception handling with rollback

#### Article V: Idiomatic Naming & Scoping (10%)
- [ ] `snake_case` for all identifiers
- [ ] Schema-qualified references (e.g., `perseus.material`)
- [ ] 63 character max identifier length
- [ ] No reserved words as identifiers

#### Article VI: Structured Error Resilience (15%)
- [ ] Specific exception types (not `WHEN OTHERS` only)
- [ ] Contextual error messages with SQLSTATE
- [ ] `RAISE EXCEPTION` with `USING HINT`

#### Article VII: Modular Logic Separation (10%)
- [ ] Schema-qualified references (prevents search_path vulnerabilities)
- [ ] Single responsibility per function/procedure
- [ ] Clear separation of concerns

### Examples

**EXEMPLARY (10.0):**
```sql
-- Perfect maintainability: clear, documented, 100% constitution
CREATE OR REPLACE FUNCTION perseus.get_upstream_materials(
    material_id_ INTEGER,
    max_depth_ INTEGER DEFAULT 10
) RETURNS TABLE(
    material_id INTEGER,
    material_name TEXT,
    depth_level INTEGER
)
LANGUAGE plpgsql
AS $$
-- Purpose: Retrieve all upstream materials for a given material ID
--          using recursive CTE (set-based, not cursor-based)
-- Parameters:
--   material_id_: Starting material ID
--   max_depth_: Maximum recursion depth (default 10, prevents infinite loops)
-- Returns: Table of upstream materials with depth level
BEGIN
    RETURN QUERY
    WITH RECURSIVE upstream AS (
        -- Base case: starting material
        SELECT
            m.material_id,
            m.material_name::TEXT,
            0 AS depth_level
        FROM perseus.material m
        WHERE m.material_id = material_id_

        UNION ALL

        -- Recursive case: parent materials
        SELECT
            m.material_id,
            m.material_name::TEXT,
            u.depth_level + 1
        FROM perseus.material m
        INNER JOIN perseus.material_transition mt ON m.material_id = mt.from_material_id
        INNER JOIN upstream u ON mt.to_material_id = u.material_id
        WHERE u.depth_level < max_depth_  -- Depth limit protection
    )
    SELECT
        upstream.material_id,
        upstream.material_name,
        upstream.depth_level
    FROM upstream
    ORDER BY upstream.depth_level, upstream.material_id;
END;
$$;

COMMENT ON FUNCTION perseus.get_upstream_materials(INTEGER, INTEGER) IS
'Retrieves all upstream materials using recursive CTE (set-based execution)';
```

**Constitution Compliance: 100%**
- ✅ Article I: Standard SQL (CTE, no vendor extensions)
- ✅ Article II: Explicit casting (`::TEXT`)
- ✅ Article III: Set-based (recursive CTE, no loops/cursors)
- ✅ Article IV: Implicit transaction (read-only function)
- ✅ Article V: snake_case, schema-qualified (`perseus.material`)
- ✅ Article VI: Depth limit prevents infinite recursion
- ✅ Article VII: Schema-qualified references throughout

**ADEQUATE (7.0):**
```sql
-- Missing documentation, 80% constitution
CREATE OR REPLACE FUNCTION get_materials(id_ INT)  -- Missing schema qualification
RETURNS TABLE(name TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT material_name::TEXT FROM material WHERE material_id = id_;  -- Missing schema
END;
$$;
```

**Constitution Compliance: 80%**
- ✅ Article I, II, III, IV: Compliant
- ❌ Article V: Missing schema qualification (violates -10%)
- ✅ Article VI, VII: Compliant (but minimal)

**FAILED (<6.0):**
```sql
-- Unreadable, <70% constitution (uses cursor, violates Article III)
CREATE OR REPLACE FUNCTION get_stuff(x INT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    cur CURSOR FOR SELECT * FROM material;  -- CURSOR (violates Article III)
    r RECORD;
BEGIN
    OPEN cur;  -- Not set-based
    LOOP
        FETCH cur INTO r;
        EXIT WHEN NOT FOUND;
        -- Do something
    END LOOP;
    CLOSE cur;
END;
$$;
```

**Constitution Compliance: 55%** (FAIL)
- ✅ Article I: Standard SQL (partial)
- ❌ Article II: Missing schema qualification, no explicit casting
- ❌ Article III: **CRITICAL VIOLATION** (uses cursor, not set-based) -20%
- ✅ Article IV: Transaction implicit
- ❌ Article V: Cryptic name (`get_stuff`), no schema -10%
- ❌ Article VI: No error handling -15%
- ❌ Article VII: Missing schema qualification -10%

### Common Issues and Deductions

| Issue | Score Deduction | Article Violated |
|-------|----------------|------------------|
| Uses WHILE loop or cursor | -3.0 to -5.0 | Article III (CRITICAL) |
| Missing schema qualification | -0.5 to -1.0 | Article V, VII |
| No error handling | -1.0 to -2.0 | Article VI |
| Cryptic variable names | -0.5 | Article V |
| Missing documentation | -0.5 to -1.0 | Best practice |
| Implicit casting | -0.5 | Article II |
| `WHEN OTHERS` without specific exceptions | -0.5 | Article VI |

---

## Dimension 5: Security (15% weight)

### Definition
No vulnerabilities, proper permissions, injection-proof queries, and secure data handling.

### Scoring Rubric

| Score | Description | Criteria |
|-------|-------------|----------|
| **10.0** | Perfect | No vulnerabilities, parameterized queries, least privilege |
| **9.0** | Very good | Minor issues like overly permissive grants |
| **8.0** | Good | No critical vulnerabilities |
| **7.0** | Adequate | No high-severity issues |
| **6.0** | Marginal | Medium-severity issues (fixable) |
| **<6.0** | Vulnerable | High/critical issues (FAIL) |

### Validation Method

```bash
# Check for SQL injection risks
grep -iE "(EXECUTE.*\|\||format.*\%s)" <file>.sql

# Check for dynamic SQL without parameterization
grep -i "EXECUTE.*||" <file>.sql

# Check permissions
psql -d perseus_dev -c "\dp perseus.material"

# Expected output: Proper role-based permissions (perseus_read, perseus_write)
```

### Security Checklist

- [ ] No SQL injection vulnerabilities (parameterized queries only)
- [ ] No string concatenation in `EXECUTE` statements
- [ ] Proper use of `format()` with `%I` (identifier) and `%L` (literal)
- [ ] Input validation for all parameters
- [ ] Least privilege permissions (no unnecessary GRANT ALL)
- [ ] No passwords or secrets in code
- [ ] Proper transaction isolation (READ COMMITTED or higher)
- [ ] No `SECURITY DEFINER` without justification

### Common Vulnerabilities

#### 1. SQL Injection via String Concatenation

**VULNERABLE:**
```sql
CREATE OR REPLACE FUNCTION get_material_by_name(material_name_ TEXT)
RETURNS TABLE(material_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    -- SQL INJECTION RISK: Direct concatenation
    RETURN QUERY EXECUTE
        'SELECT material_id FROM perseus.material WHERE material_name = '''
        || material_name_ || '''';
END;
$$;

-- Exploit: material_name_ = "'; DROP TABLE perseus.material; --"
```

**SECURE:**
```sql
CREATE OR REPLACE FUNCTION perseus.get_material_by_name(material_name_ TEXT)
RETURNS TABLE(material_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    -- SECURE: Parameterized query
    RETURN QUERY EXECUTE
        'SELECT material_id FROM perseus.material WHERE material_name = $1'
    USING material_name_;

    -- OR: Static query (no dynamic SQL needed)
    RETURN QUERY
    SELECT m.material_id
    FROM perseus.material m
    WHERE m.material_name = material_name_;
END;
$$;
```

#### 2. Dynamic Table/Column Names

**VULNERABLE:**
```sql
-- SQL INJECTION RISK: Unvalidated identifier
EXECUTE 'SELECT * FROM ' || table_name;
```

**SECURE:**
```sql
-- SECURE: Use %I for identifier, validates/quotes properly
EXECUTE format('SELECT * FROM %I', table_name);

-- BETTER: Whitelist validation
IF table_name NOT IN ('material', 'arc', 'goo') THEN
    RAISE EXCEPTION 'Invalid table name: %', table_name;
END IF;
EXECUTE format('SELECT * FROM perseus.%I', table_name);
```

#### 3. Overly Permissive Grants

**VULNERABLE:**
```sql
-- Too permissive: All users can modify data
GRANT ALL ON perseus.material TO PUBLIC;
```

**SECURE:**
```sql
-- Least privilege: Role-based access
GRANT SELECT ON perseus.material TO perseus_read;
GRANT INSERT, UPDATE, DELETE ON perseus.material TO perseus_write;
GRANT ALL ON perseus.material TO perseus_admin;
```

### Examples

**PERFECT (10.0):**
```sql
CREATE OR REPLACE PROCEDURE perseus.update_material_status(
    material_id_ INTEGER,
    new_status_ TEXT
)
LANGUAGE plpgsql
SECURITY INVOKER  -- Runs with caller's permissions (not elevated)
AS $$
BEGIN
    -- Input validation
    IF material_id_ IS NULL THEN
        RAISE EXCEPTION 'material_id cannot be NULL'
            USING ERRCODE = 'null_value_not_allowed';
    END IF;

    IF new_status_ NOT IN ('active', 'inactive', 'archived') THEN
        RAISE EXCEPTION 'Invalid status: %. Must be active, inactive, or archived', new_status_
            USING ERRCODE = 'invalid_parameter_value';
    END IF;

    -- Parameterized query (no injection risk)
    UPDATE perseus.material
    SET status = new_status_,
        updated_at = CURRENT_TIMESTAMP
    WHERE material_id = material_id_;

    -- Log audit trail
    INSERT INTO perseus.audit_log (table_name, record_id, action, changed_by)
    VALUES ('material', material_id_, 'status_update', current_user);
END;
$$;

-- Proper permissions
GRANT EXECUTE ON PROCEDURE perseus.update_material_status TO perseus_write;
```

**ACCEPTABLE (7.0):**
```sql
-- Minor issue: Missing input validation
CREATE OR REPLACE FUNCTION perseus.get_material_count()
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM perseus.material;
    RETURN v_count;
END;
$$;

-- Slightly too permissive (read-only function should be granted to perseus_read)
GRANT EXECUTE ON FUNCTION perseus.get_material_count TO PUBLIC;
```

**FAILED (<6.0):**
```sql
-- CRITICAL: SQL injection vulnerability
CREATE OR REPLACE FUNCTION get_data(table_name TEXT)
RETURNS TABLE(id INT, name TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- SQL INJECTION: Direct concatenation without validation
    RETURN QUERY EXECUTE 'SELECT id, name FROM ' || table_name;
END;
$$;
```

### Common Issues and Deductions

| Issue | Score Deduction | Severity |
|-------|----------------|----------|
| SQL injection via concatenation | -4.0 to -5.0 | CRITICAL |
| Dynamic SQL without parameterization | -3.0 | HIGH |
| Missing input validation | -1.0 | MEDIUM |
| Overly permissive GRANT ALL | -0.5 to -1.0 | MEDIUM |
| `SECURITY DEFINER` without justification | -1.0 | MEDIUM |
| No audit logging for DML operations | -0.5 | LOW |
| Hardcoded credentials | -5.0 | CRITICAL |

---

## Overall Score Calculation

### Formula

```
Overall Score = (Syntax × 0.20) + (Logic × 0.30) + (Performance × 0.20)
                + (Maintainability × 0.15) + (Security × 0.15)
```

### Calculation Example

**Object:** `perseus.addarc` (procedure)

| Dimension | Score | Weight | Weighted Score |
|-----------|-------|--------|----------------|
| **Syntax Correctness** | 9.0/10 | 20% | 1.80 |
| **Logic Preservation** | 8.5/10 | 30% | 2.55 |
| **Performance** | 8.0/10 | 20% | 1.60 |
| **Maintainability** | 8.5/10 | 15% | 1.28 |
| **Security** | 8.0/10 | 15% | 1.20 |
| **TOTAL** | **8.43** | **100%** | **8.43** |

**Final Overall Score:** **8.4/10.0** (rounded to 1 decimal place)

### Weighted Score Calculation (Step-by-Step)

```
Syntax Weighted:         9.0 × 0.20 = 1.80
Logic Weighted:          8.5 × 0.30 = 2.55
Performance Weighted:    8.0 × 0.20 = 1.60
Maintainability Weighted: 8.5 × 0.15 = 1.28
Security Weighted:       8.0 × 0.15 = 1.20
                                    ------
Overall Score:                      8.43 → 8.4/10.0
```

---

## Quality Gates

### Minimum Score Thresholds

| Dimension | DEV | STAGING | PROD |
|-----------|-----|---------|------|
| **Syntax Correctness** | 6.0 | 7.0 | 7.0 |
| **Logic Preservation** | 6.0 | 7.0 | 7.0 |
| **Performance** | 5.0 | 6.0 | 6.0 |
| **Maintainability** | 5.0 | 6.0 | 7.0 |
| **Security** | 6.0 | 7.0 | 8.0 |
| **Overall Score** | **6.0** | **7.0** | **8.0** |

### Deployment Gates

| Environment | Minimum Overall | Minimum Per-Dimension | Additional Requirements |
|-------------|----------------|----------------------|-------------------------|
| **DEV** | 6.0/10.0 | 5.0/10.0 | Can deploy with issues for testing |
| **STAGING** | 7.0/10.0 | 6.0/10.0 | Zero P0/P1 issues, all tests passing |
| **PROD** | 8.0/10.0 (target) | 6.0/10.0 | STAGING sign-off + rollback plan |

**Gate Enforcement:**
- DEV: Soft gate (warnings only, deployment allowed)
- STAGING: Hard gate (deployment blocked if score <7.0)
- PROD: Hard gate (deployment blocked if score <8.0, exceptions require DBA approval)

### Issue Severity Mapping

Quality scores map to issue severity (P0-P3):

| Overall Score | Severity | Action Required |
|---------------|----------|----------------|
| **<6.0** | **P0 (Critical)** | Block ALL deployment, fix immediately |
| **6.0-6.9** | **P1 (High)** | Block PROD deployment, fix before PROD |
| **7.0-7.9** | **P2 (Medium)** | Fix before STAGING preferred |
| **8.0-8.9** | **P3 (Low)** | Track for improvement |
| **≥9.0** | **Excellent** | No action needed |

### Dimension-Specific Severity

Individual dimension scores <6.0 automatically escalate to P0:

| Dimension | Score | Severity | Rationale |
|-----------|-------|----------|-----------|
| Syntax | <6.0 | P0 | Object doesn't compile, blocks all testing |
| Logic | <6.0 | P0 | Business logic broken, data integrity risk |
| Performance | <6.0 | P1 | Acceptable slowdown for non-critical objects |
| Maintainability | <6.0 | P1 | Technical debt, but functional |
| Security | <6.0 | P0 | Vulnerabilities unacceptable in production |

---

## Automated Scoring

### Command-Line Tools

```bash
# Full analysis with quality score
python3 scripts/automation/analyze-object.py procedure addarc

# Expected output:
# ================================================================================
# QUALITY SCORE ANALYSIS: perseus.addarc
# ================================================================================
#
# Overall Score: 8.4/10.0 ✅ PASS (exceeds 7.0 minimum)
#
# Dimension Breakdown:
#   Syntax Correctness:    9.0/10 (20% weight) → 1.80
#   Logic Preservation:    8.5/10 (30% weight) → 2.55
#   Performance:           8.0/10 (20% weight) → 1.60
#   Maintainability:       8.5/10 (15% weight) → 1.28
#   Security:              8.0/10 (15% weight) → 1.20
#                                              ------
#   OVERALL:               8.4/10.0            8.43
#
# Constitution Compliance: 97.5%
# Deployment Readiness: ✅ DEV, STAGING, PROD
# Issues: 0 P0, 0 P1, 1 P2, 2 P3

# Score only (for CI/CD)
python3 scripts/automation/analyze-object.py procedure addarc --score-only
# Output: 8.4
```

### CI/CD Integration

```yaml
# GitHub Actions example
name: Quality Gate Check
on: [pull_request]

jobs:
  quality_check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Run quality analysis
        run: |
          python3 scripts/automation/analyze-object.py procedure ${{ matrix.procedure }} --score-only > score.txt
          SCORE=$(cat score.txt)

          if (( $(echo "$SCORE < 7.0" | bc -l) )); then
            echo "ERROR: Quality score $SCORE below 7.0 minimum for STAGING"
            exit 1
          fi

          echo "✅ Quality score $SCORE meets requirements"
```

---

## Detailed Examples

### Example 1: Excellent Score (9.2/10.0)

**Object:** `perseus.addarc` (procedure)

#### Dimensional Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| **Syntax** | 9.5/10 | Perfect PostgreSQL 17 syntax, schema-qualified, explicit casting |
| **Logic** | 9.0/10 | 100% preserved, all edge cases handled, identical behavior |
| **Performance** | 9.0/10 | 15% faster than SQL Server baseline (97ms → 82ms) |
| **Maintainability** | 9.0/10 | Clear, well-documented, 100% constitution compliance |
| **Security** | 9.0/10 | Parameterized, proper permissions, input validation |

#### Calculation

```
Syntax:         9.5 × 0.20 = 1.90
Logic:          9.0 × 0.30 = 2.70
Performance:    9.0 × 0.20 = 1.80
Maintainability: 9.0 × 0.15 = 1.35
Security:       9.0 × 0.15 = 1.35
                            ------
Overall:                    9.10 → 9.1/10.0 ✅ EXCELLENT
```

#### Assessment

- **Overall:** 9.1/10.0 ✅ EXCELLENT
- **Constitution:** 100% compliant
- **Deployment:** Ready for all environments (DEV, STAGING, PROD)
- **Issues:** 0 P0, 0 P1, 0 P2, 0 P3
- **Recommendation:** Deploy immediately, use as template for other procedures

---

### Example 2: Acceptable Score (7.5/10.0)

**Object:** `perseus.legacy_report` (view)

#### Dimensional Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| **Syntax** | 8.0/10 | Uses deprecated `SERIAL` syntax (should use `GENERATED ALWAYS AS IDENTITY`) |
| **Logic** | 7.5/10 | Logic preserved, missing 2 edge cases (NULL handling for optional columns) |
| **Performance** | 7.0/10 | 18% slower than SQL Server (within 20% tolerance) |
| **Maintainability** | 7.5/10 | Readable, 85% constitution compliance (missing some schema qualifications) |
| **Security** | 8.0/10 | No critical issues, minor: missing input validation on filtering parameters |

#### Calculation

```
Syntax:         8.0 × 0.20 = 1.60
Logic:          7.5 × 0.30 = 2.25
Performance:    7.0 × 0.20 = 1.40
Maintainability: 7.5 × 0.15 = 1.13
Security:       8.0 × 0.15 = 1.20
                            ------
Overall:                    7.58 → 7.6/10.0 ✅ ACCEPTABLE
```

#### Assessment

- **Overall:** 7.6/10.0 ✅ ACCEPTABLE (exceeds 7.0 minimum for STAGING)
- **Constitution:** 85% compliant
- **Deployment:** Ready for DEV and STAGING, requires minor fixes for PROD
- **Issues:** 0 P0, 0 P1, 2 P2, 1 P3
- **Recommendation:** Deploy to STAGING, fix P2 issues before PROD

#### Identified Issues

| Issue | Severity | Dimension | Fix |
|-------|----------|-----------|-----|
| Deprecated `SERIAL` syntax | P2 | Syntax | Replace with `GENERATED ALWAYS AS IDENTITY` |
| Missing NULL handling for 2 columns | P2 | Logic | Add `COALESCE()` for default values |
| 18% slower than baseline | P3 | Performance | Add index on filter column |

---

### Example 3: Failed Score (5.8/10.0)

**Object:** `perseus.broken_function` (function)

#### Dimensional Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| **Syntax** | 6.0/10 | Compiles with 3 warnings (minor), but functional |
| **Logic** | 5.0/10 | **Missing critical business logic** (validation step omitted) |
| **Performance** | 6.5/10 | 25% slower than baseline (exceeds 20% tolerance marginally) |
| **Maintainability** | 6.0/10 | Hard to read, 72% constitution (uses cursor, violates Article III) |
| **Security** | 6.0/10 | Minor SQL injection risk (dynamic table name not validated) |

#### Calculation

```
Syntax:         6.0 × 0.20 = 1.20
Logic:          5.0 × 0.30 = 1.50  ❌ Below 6.0 threshold
Performance:    6.5 × 0.20 = 1.30
Maintainability: 6.0 × 0.15 = 0.90
Security:       6.0 × 0.15 = 0.90
                            ------
Overall:                    5.80 → 5.8/10.0 ❌ FAILED
```

#### Assessment

- **Overall:** 5.8/10.0 ❌ FAILED (below 6.0 minimum)
- **Constitution:** 72% compliant (violates Article III - uses cursor)
- **Deployment:** **BLOCKED for all environments**
- **Issues:** 1 P0 (Logic <6.0), 2 P1, 3 P2
- **Recommendation:** **DO NOT DEPLOY** - Fix P0 issue immediately

#### Identified Issues

| Issue | Severity | Dimension | Fix |
|-------|----------|-----------|-----|
| **Missing critical validation logic** | **P0** | **Logic** | **Add business rule validation from SQL Server original** |
| Uses cursor instead of set-based query | P1 | Maintainability | Refactor to CTE or window function |
| 25% performance regression | P1 | Performance | Optimize query, add indexes |
| Dynamic table name not validated | P2 | Security | Add whitelist validation or use `format('%I', ...)` |
| Missing schema qualification | P2 | Maintainability | Add schema prefix to all references |

---

## Quality Improvement Process

### Iterative Improvement Workflow

When score <7.0, follow this systematic process:

#### Step 1: Identify Lowest-Scoring Dimension(s)

```bash
python3 scripts/automation/analyze-object.py procedure broken_function

# Output identifies lowest score:
# Logic Preservation: 5.0/10 ❌ (below 6.0 threshold)
```

#### Step 2: Review Dimension-Specific Checklist

Consult the dimension section of this document:
- **Syntax:** Section "Dimension 1: Syntax Correctness"
- **Logic:** Section "Dimension 2: Logic Preservation"
- **Performance:** Section "Dimension 3: Performance"
- **Maintainability:** Section "Dimension 4: Maintainability"
- **Security:** Section "Dimension 5: Security"

#### Step 3: Apply Fixes Systematically

**For Logic Preservation (5.0/10):**

1. Compare SQL Server original vs PostgreSQL migrated
2. Identify missing business logic (validation, edge cases)
3. Add missing logic with proper error handling
4. Update unit tests to cover all scenarios

**Before (5.0/10):**
```sql
CREATE OR REPLACE FUNCTION perseus.process_order(order_id_ INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    -- Missing validation: order must exist and be in 'pending' status
    UPDATE perseus.orders SET status = 'processed' WHERE order_id = order_id_;
END;
$$;
```

**After (8.5/10):**
```sql
CREATE OR REPLACE FUNCTION perseus.process_order(order_id_ INTEGER)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status TEXT;
BEGIN
    -- ADDED: Validate order exists
    SELECT status INTO v_current_status
    FROM perseus.orders
    WHERE order_id = order_id_;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Order % does not exist', order_id_
            USING ERRCODE = 'no_data_found';
    END IF;

    -- ADDED: Validate order status
    IF v_current_status != 'pending' THEN
        RAISE EXCEPTION 'Order % is not in pending status (current: %)', order_id_, v_current_status
            USING ERRCODE = 'invalid_row_count_in_update';
    END IF;

    -- Process order
    UPDATE perseus.orders
    SET status = 'processed',
        processed_at = CURRENT_TIMESTAMP
    WHERE order_id = order_id_;
END;
$$;
```

#### Step 4: Re-Score After Changes

```bash
python3 scripts/automation/analyze-object.py procedure process_order

# New output:
# Overall Score: 8.5/10.0 ✅ PASS
# Logic Preservation: 8.5/10 (improved from 5.0)
```

#### Step 5: Iterate Until ≥7.0/10.0

Repeat steps 1-4 for each dimension below threshold.

**Target Goals:**
- STAGING deployment: ≥7.0/10.0 overall, all dimensions ≥6.0
- PROD deployment: ≥8.0/10.0 overall, all dimensions ≥6.0

---

## Frequently Asked Questions

### Q1: What if a dimension is below 6.0 but overall is ≥7.0?

**A:** Deployment is **blocked**. All dimensions must meet minimum thresholds:
- DEV: All dimensions ≥5.0
- STAGING: All dimensions ≥6.0
- PROD: All dimensions ≥6.0

**Example:**
```
Syntax:         9.0 × 0.20 = 1.80
Logic:          9.5 × 0.30 = 2.85
Performance:    9.0 × 0.20 = 1.80
Maintainability: 5.5 × 0.15 = 0.83  ❌ Below 6.0
Security:       8.0 × 0.15 = 1.20
                            ------
Overall:                    8.48 → 8.5/10.0

Result: BLOCKED for STAGING/PROD (Maintainability <6.0)
```

### Q2: Can I deploy with 6.9/10.0 to STAGING?

**A:** No. STAGING requires ≥7.0/10.0. Round down for gate checks:
- 6.95 → 7.0 (rounds up) → **ALLOWED**
- 6.94 → 6.9 (rounds down) → **BLOCKED**

### Q3: What if performance is 25% slower but other dimensions are perfect?

**A:** Deployment **blocked** (performance <6.0). Exception process:
1. Document performance regression in issue tracker
2. Provide justification (e.g., correctness vs speed tradeoff)
3. DBA approval required for PROD deployment
4. Create optimization task for next sprint

### Q4: How do I calculate constitution compliance percentage?

**A:** Average compliance across all 7 articles:

```
Article I:   100% (full compliance)
Article II:  100%
Article III: 100%
Article IV:   95% (minor: missing ROLLBACK in one path)
Article V:   100%
Article VI:   90% (uses WHEN OTHERS without specific exception)
Article VII: 100%
                -----
Average:      97.9% → 98% constitution compliance
```

**Mapping to Maintainability Score:**
- 100% → 10.0
- 95-99% → 9.0
- 90-94% → 8.0
- 80-89% → 7.0
- 70-79% → 6.0
- <70% → <6.0 (FAIL)

### Q5: Do I need to score every single change?

**A:** No. Score at these milestones:
- Initial migration (baseline score)
- After major refactoring (verify improvement)
- Before STAGING deployment (gate check)
- Before PROD deployment (gate check)
- Quarterly reviews (quality trend analysis)

### Q6: What if my object has no SQL Server baseline for performance?

**A:** For new objects (no SQL Server equivalent):
1. Capture PostgreSQL baseline using performance framework
2. Performance dimension score = 8.0 (default for new objects)
3. Monitor performance for 2 weeks
4. Adjust score if issues arise

### Q7: Can I challenge a quality score?

**A:** Yes. Escalation process:
1. Document disagreement with specific evidence
2. Submit to DBA for review
3. DBA re-evaluates dimension scores
4. Final score adjusted if warranted
5. Document decision in object's quality report

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| **1.0** | 2026-01-25 | Perseus Migration Project | Initial methodology, 5 dimensions, 7 constitutional principles |

---

## References

### Project Documentation
- `.specify/memory/constitution.md` - 7 binding core principles
- `docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md` - Articles I-XVII
- `docs/PROJECT-SPECIFICATION.md` - Requirements and constraints
- `CLAUDE.md` - Project overview and workflows

### Quality Reports (Examples)
- `scripts/validation/T017-QUALITY-REPORT.md` - Phase gate check script (8.5/10.0)
- `scripts/validation/T014-COMPLETION-SUMMARY.md` - Performance test framework (8.5/10.0)
- `scripts/deployment/T018-QUALITY-REPORT.md` - Deployment script (8.7/10.0)

### Validation Scripts
- `scripts/validation/syntax-check.sh` - Syntax validation
- `scripts/validation/dependency-check.sql` - Dependency validation
- `scripts/validation/performance-test-framework.sql` - Performance benchmarking

### Automation Tools
- `scripts/automation/analyze-object.py` - Automated quality scoring (planned)

---

**Document Status:** Active
**Approval:** Pending DBA review
**Next Review:** After Sprint 4 completion (all procedures/views complete)
