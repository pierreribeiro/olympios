# PostgreSQL Programming Constitution v2.0

## Perseus Database Migration Project - Authoritative Programming Standards

**Document Type:** Constitution (Binding Law)  
**Target Audience:** Claude Code, Claude Desktop, AI Agents, DBAs, Developers  
**PostgreSQL Version:** 17+  
**Created:** 2026-01-13  
**Updated:** 2026-04-14  
**Authors:** Pierre Ribeiro + Claude (Desktop Command Center)  
**Status:** ACTIVE - MANDATORY COMPLIANCE  
**Tags:** `#DOC:CONSTITUTION:V2` `@ACTIVE` `~PRODUCTION` `!CRITICAL`

---

## Preamble

This Constitution establishes the binding programming standards for all PostgreSQL code produced during the Perseus Database Migration project. These principles ensure code quality, performance, maintainability, testability, and consistency across all database objects: tables, indexes, views, functions, procedures, triggers, sequences, and Foreign Data Wrapper configurations.

**Version 2.0** elevates Test-Driven Development from an optional practice to a constitutional mandate. Every database object — whether newly created, migrated from SQL Server, or refactored for optimization — SHALL be developed using the Red-Green-Refactor cycle with pgTAP as the mandatory testing framework. Code without tests is incomplete code. Tests written after implementation do not constitute TDD.

**The two foundational principles of this Constitution are:**

1. **Correctness through testing** — No code is considered production-ready until it passes a comprehensive pgTAP test suite written before or concurrently with implementation.
2. **Quality through standards** — All code must conform to the naming, typing, formatting, security, and performance standards defined herein.

**Compliance is mandatory. No exceptions without documented justification and DBA approval.**

---

## PART I: CODING STANDARDS

---

## Article I: Naming Conventions

### Section 1.1 - Universal Naming Rules

All database objects SHALL:

1. Use **lowercase `snake_case`** exclusively
2. Start with a letter (a-z)
3. Contain only letters, numbers, and underscores
4. Not exceed **63 characters** (PostgreSQL identifier limit)
5. Avoid SQL reserved words and PostgreSQL keywords
6. Never use the `pg_` prefix (reserved for system objects)
7. Never use dollar signs (`$`) or non-ASCII characters

### Section 1.2 - Object-Specific Prefixes and Suffixes

| Object Type          | Convention         | Example                       |
| -------------------- | ------------------ | ----------------------------- |
| Tables               | Plural nouns       | `customers`, `order_items`    |
| Views                | Prefix `v_`        | `v_active_customers`          |
| Materialized Views   | Prefix `mv_`       | `mv_monthly_sales`            |
| Temporary Tables     | Prefix `tmp_`      | `tmp_processing_batch`        |
| Sequences            | Suffix `_seq`      | `customer_id_seq`             |
| Primary Key Index    | Suffix `_pkey`     | `customers_pkey`              |
| Unique Index         | Suffix `_key`      | `customers_email_key`         |
| Standard Index       | Suffix `_idx`      | `orders_customer_id_idx`      |
| Exclusion Constraint | Suffix `_excl`     | `reservations_room_excl`      |
| Foreign Key          | Suffix `_fkey`     | `orders_customer_id_fkey`     |
| Check Constraint     | Suffix `_check`    | `orders_amount_check`         |
| Functions            | Action verb prefix | `get_customer_by_id()`        |
| Procedures           | Action verb prefix | `process_order_batch()`       |
| Triggers             | Prefix `trg_`      | `trg_audit_customer_changes`  |
| Types                | Suffix `_type`     | `address_type`                |
| Enums                | Suffix `_enum`     | `order_status_enum`           |
| **Test Files**       | Prefix `test_`     | `test_get_customer_by_id.sql` |
| **Test Schema**      | Fixed name         | `tests`                       |

### Section 1.3 - Function Naming Patterns

Functions MUST begin with action verbs indicating their operation:

| Prefix       | Purpose                   | Example                       |
| ------------ | ------------------------- | ----------------------------- |
| `get_`       | Read/SELECT operations    | `get_customer_by_id()`        |
| `select_`    | Query returning resultset | `select_active_orders()`      |
| `insert_`    | Single insert operation   | `insert_customer()`           |
| `update_`    | Update operation          | `update_customer_status()`    |
| `delete_`    | Delete operation          | `delete_inactive_customers()` |
| `upsert_`    | Insert or update          | `upsert_product()`            |
| `process_`   | Complex business logic    | `process_monthly_billing()`   |
| `validate_`  | Validation logic          | `validate_email_format()`     |
| `calculate_` | Computation               | `calculate_order_total()`     |
| `sync_`      | Synchronization           | `sync_inventory_levels()`     |

### Section 1.4 - Parameter and Variable Naming

1. **Parameters**: Use named notation, never positional

2. **Conflict Resolution**: Append underscore when parameter names conflict with column names
   
   ```sql
   -- CORRECT: Disambiguates parameter from column
   CREATE FUNCTION get_customer(customer_id_ BIGINT)
   ```

3. **Boolean Columns**: Use `is_` or `has_` prefix (`is_active`, `has_subscription`)

4. **Primary Keys**: Use `id` or `_id` suffix (`customer_id`, `order_id`)

5. **Temporal Columns**: Use `_at` suffix (`created_at`, `updated_at`, `deleted_at`)

6. **Foreign Keys**: Match referenced table singular + `_id` (`customer_id` references `customers`)

### Section 1.5 - Test Naming Conventions

Test files and test descriptions MUST follow these patterns:

1. **Test file names**: `test_<object_name>.sql` (e.g., `test_reconcile_mupstream.sql`)

2. **Test descriptions**: Plain English sentences describing expected behavior
   
   ```sql
   -- CORRECT: Descriptive test names
   SELECT ok(
       has_function('reconcile_mupstream'),
       'Function reconcile_mupstream should exist'
   );
   
   SELECT results_eq(
       'SELECT calculate_order_total(100, 0.08)',
       'SELECT 108.00::NUMERIC',
       'calculate_order_total should apply 8% tax to base amount'
   );
   ```

3. **Test organization**: One test file per database object or closely related group

4. **Test schema**: All test helper functions reside in the `tests` schema

---

## Article II: Data Type Standards

### Section 2.1 - Primary Key Strategy

1. **Preferred Type**: `BIGINT` for all primary keys
2. **Generation**: Use `GENERATED ALWAYS AS IDENTITY` (not `SERIAL`)
3. **String PKs**: Maximum 64 bytes if absolutely necessary
4. **UUID**: Acceptable for distributed systems; use `gen_random_uuid()`

```sql
-- CORRECT: Identity column
CREATE TABLE customers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ...
);

-- AVOID: SERIAL (legacy, has sequence gap issues)
-- CREATE TABLE customers (id SERIAL PRIMARY KEY, ...);
```

### Section 2.2 - Numeric Types

| Type               | Usage                      | Notes                               |
| ------------------ | -------------------------- | ----------------------------------- |
| `INTEGER`          | General numeric fields     | 4 bytes, -2B to +2B                 |
| `BIGINT`           | IDs, large counts          | 8 bytes, default when uncertain     |
| `SMALLINT`         | AVOID                      | Negligible savings, overflow risk   |
| `NUMERIC(p,s)`     | Financial/precise decimals | Specify precision and scale         |
| `MONEY`            | Currency values            | Use with caution (locale-dependent) |
| `REAL`             | Scientific, low-precision  | NEVER use equality comparisons      |
| `DOUBLE PRECISION` | Scientific, coordinates    | NEVER use equality comparisons      |

### Section 2.3 - String Types

| Type         | Usage            | Notes                         |
| ------------ | ---------------- | ----------------------------- |
| `TEXT`       | Unlimited text   | Preferred for flexibility     |
| `VARCHAR(n)` | Constrained text | Enforces data quality         |
| `CHAR(n)`    | AVOID            | Pads with spaces, no benefits |

### Section 2.4 - Temporal Types

1. **MANDATORY**: Store all timestamps as `TIMESTAMPTZ` (timestamp with time zone)
2. **MANDATORY**: Store in UTC timezone
3. **Format**: Use ISO-8601 for input/output (`YYYY-MM-DD HH:MI:SS`)
4. **Date-only**: Use `DATE` type
5. **Time-only**: Use `TIME` or `TIMETZ`
6. **Intervals**: Use `INTERVAL` type for durations

```sql
-- CORRECT
created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP

-- AVOID: TIMESTAMP without timezone
-- created_at TIMESTAMP NOT NULL
```

### Section 2.5 - Boolean Types

1. Use native `BOOLEAN` type
2. Column names MUST use `is_` or `has_` prefix
3. Default explicitly: `DEFAULT FALSE` or `DEFAULT TRUE`

### Section 2.6 - Enumerated Types

Use `ENUM` for columns with:

- Fixed, small value sets (< 12 values)
- Values that rarely change
- Values requiring validation

```sql
CREATE TYPE order_status_enum AS ENUM (
    'pending', 'confirmed', 'processing', 
    'shipped', 'delivered', 'cancelled'
);
```

### Section 2.7 - JSON Types

| Type    | Usage                | Notes                |
| ------- | -------------------- | -------------------- |
| `JSONB` | Queryable JSON       | Indexable, preferred |
| `JSON`  | Preserved formatting | Rare use cases only  |

**MANDATORY**: Use `JSONB` for any JSON that will be queried or indexed.

### Section 2.8 - NULL Handling Principles

1. **Semantic Equivalence**: If zero and NULL mean the same thing, enforce `NOT NULL`
2. **Comparison**: Use `IS NULL` for NULL checks, `=` for value checks
3. **Safe Comparison**: Use `IS DISTINCT FROM` for NULL-safe comparisons
4. **Aggregation**: Use `COALESCE()` to handle NULLs in aggregates
5. **Default Values**: Prefer explicit defaults over NULL where semantically appropriate

```sql
-- NULL-safe comparison
WHERE column_a IS DISTINCT FROM column_b

-- Aggregate with NULL handling
SELECT COALESCE(SUM(amount), 0) AS total
```

---

## Article III: SQL Statement Standards

### Section 3.1 - SELECT Statement Rules

**PROHIBITION**: Never use `SELECT *` in production code.

**MANDATORY**:

1. Enumerate all required columns explicitly
2. Qualify column names with table aliases in multi-table queries
3. Use meaningful table aliases (not single letters like `a`, `b`)

```sql
-- CORRECT
SELECT 
    c.id,
    c.name,
    c.email,
    o.order_date,
    o.total_amount
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE c.is_active = TRUE;

-- PROHIBITED
SELECT * FROM customers c JOIN orders o ON o.customer_id = c.id;
```

### Section 3.2 - Query Optimization Rules

1. **Index Coverage**: All online queries MUST have supporting indexes
   
   - Exception: Tables < 100 rows or < 100KB
   - Exception: Very low-frequency operations

2. **Avoid Full Table Scans**: Ensure WHERE clauses use indexed columns

3. **Negation Operators**: AVOID `!=` or `<>` as first filter condition
   
   ```sql
   -- AVOID: Causes full table scan
   WHERE status != 'deleted'
   
   -- PREFER: Use positive condition with index
   WHERE status IN ('active', 'pending', 'completed')
   ```

4. **EXISTS vs IN**: Use `EXISTS` for subqueries
   
   ```sql
   -- PREFER
   WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.id)
   
   -- AVOID for large datasets
   WHERE customer_id IN (SELECT id FROM customers WHERE ...)
   ```

5. **Array Comparison**: Use `= ANY()` instead of `IN` for value lists
   
   ```sql
   -- PREFER
   WHERE status = ANY(ARRAY['active', 'pending'])
   
   -- ACCEPTABLE for small lists
   WHERE status IN ('active', 'pending')
   ```

6. **Fuzzy Search**: Left-wildcard patterns cannot use B-tree indexes
   
   ```sql
   -- CANNOT use index
   WHERE name LIKE '%smith'
   
   -- CAN use index (right-wildcard)
   WHERE name LIKE 'smith%'
   
   -- For left-wildcard, create reverse() functional index
   ```

7. **Existence Checks**: Use LIMIT 1, not COUNT(*)
   
   ```sql
   -- CORRECT
   SELECT EXISTS(SELECT 1 FROM orders WHERE customer_id = 123 LIMIT 1);
   
   -- INEFFICIENT
   SELECT COUNT(*) > 0 FROM orders WHERE customer_id = 123;
   ```

### Section 3.3 - RETURNING Clause Usage

Use `RETURNING` to retrieve data after DML operations:

```sql
INSERT INTO customers (name, email)
VALUES ('John Doe', 'john@example.com')
RETURNING id, created_at;

UPDATE orders 
SET status = 'shipped', shipped_at = CURRENT_TIMESTAMP
WHERE id = 123
RETURNING id, status, shipped_at;
```

### Section 3.4 - UPSERT Pattern

Use `INSERT ... ON CONFLICT` for upsert operations:

```sql
INSERT INTO products (sku, name, price)
VALUES ('ABC123', 'Widget', 29.99)
ON CONFLICT (sku) 
DO UPDATE SET 
    name = EXCLUDED.name,
    price = EXCLUDED.price,
    updated_at = CURRENT_TIMESTAMP
RETURNING id;
```

---

## Article IV: Common Table Expressions (CTEs)

### Section 4.1 - CTE vs Temporary Tables

**PREFER CTEs over temporary tables** for intermediate results:

| Feature           | CTEs                      | Temp Tables         |
| ----------------- | ------------------------- | ------------------- |
| Memory Usage      | Lower (no table creation) | Higher              |
| Readability       | Better (inline)           | Worse (separate)    |
| Indexing          | Not possible              | Possible            |
| Reuse in Query    | Multiple references       | Multiple references |
| Transaction Scope | Query-scoped              | Session-scoped      |

### Section 4.2 - CTE Best Practices

1. **Naming**: Use descriptive names reflecting the data subset
2. **Materialization**: PostgreSQL 12+ allows `MATERIALIZED` / `NOT MATERIALIZED` hints
3. **Recursive CTEs**: Always include termination conditions and depth limits

```sql
-- Example: Well-structured CTE
WITH active_customers AS (
    SELECT id, name, email
    FROM customers
    WHERE is_active = TRUE
      AND deleted_at IS NULL
),
recent_orders AS (
    SELECT 
        customer_id,
        COUNT(*) AS order_count,
        SUM(total_amount) AS total_spent
    FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY customer_id
)
SELECT 
    ac.id,
    ac.name,
    COALESCE(ro.order_count, 0) AS order_count,
    COALESCE(ro.total_spent, 0) AS total_spent
FROM active_customers ac
LEFT JOIN recent_orders ro ON ro.customer_id = ac.id
ORDER BY total_spent DESC;
```

### Section 4.3 - Recursive CTE Safety

**MANDATORY** for recursive CTEs:

1. Include termination condition
2. Consider `LIMIT` clause for safety
3. Use cycle detection for graph traversals

```sql
-- Safe recursive CTE with depth limit
WITH RECURSIVE hierarchy AS (
    -- Anchor member
    SELECT id, parent_id, name, 1 AS depth
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    -- Recursive member with depth limit
    SELECT c.id, c.parent_id, c.name, h.depth + 1
    FROM categories c
    JOIN hierarchy h ON h.id = c.parent_id
    WHERE h.depth < 10  -- Safety limit
)
SELECT * FROM hierarchy;
```

---

## Article V: Functions and Procedures

### Section 5.1 - Functions vs Procedures Decision Matrix

| Characteristic      | Function              | Procedure                     |
| ------------------- | --------------------- | ----------------------------- |
| Return Value        | REQUIRED              | Optional (OUT params)         |
| Use in SQL          | YES                   | NO (CALL only)                |
| Transaction Control | NO                    | YES (COMMIT/ROLLBACK)         |
| Best For            | Calculations, queries | Multi-step operations         |
| **TDD Testability** | **Direct (SELECT)**   | **Requires wrapper strategy** |

### Section 5.2 - Function Volatility Classification

**MANDATORY**: Always specify volatility category:

| Category    | Description                        | Use Case                        |
| ----------- | ---------------------------------- | ------------------------------- |
| `IMMUTABLE` | Same output for same input, always | Pure calculations, constants    |
| `STABLE`    | Same output within single query    | Lookups, current_user           |
| `VOLATILE`  | Output may change anytime          | Modifying data, random(), clock |

```sql
-- CORRECT: Explicit volatility
CREATE OR REPLACE FUNCTION calculate_tax(amount NUMERIC)
RETURNS NUMERIC
LANGUAGE SQL
IMMUTABLE
PARALLEL SAFE
AS $$
    SELECT amount * 0.08;
$$;
```

### Section 5.3 - Additional Function Attributes

Specify when applicable:

| Attribute                    | Usage                                  |
| ---------------------------- | -------------------------------------- |
| `PARALLEL SAFE`              | Can run in parallel query              |
| `PARALLEL RESTRICTED`        | Cannot run in parallel worker          |
| `PARALLEL UNSAFE`            | Prevents parallelization               |
| `RETURNS NULL ON NULL INPUT` | Skip execution if any arg is NULL      |
| `STRICT`                     | Synonym for RETURNS NULL ON NULL INPUT |
| `SECURITY DEFINER`           | Execute as function owner              |
| `SECURITY INVOKER`           | Execute as calling user (default)      |

### Section 5.4 - Function Design Principles

**Functions ARE appropriate for:**

- Encapsulating transactions
- Reducing network round trips
- Small amounts of custom logic
- Data validation
- Calculated columns

**Functions are NOT appropriate for:**

- Complex computations (use application layer)
- Frequent type conversions
- Heavy ETL processing
- Long-running operations

### Section 5.5 - Procedure Design Principles

Use procedures when you need:

- Transaction control (COMMIT/ROLLBACK within procedure)
- Multi-step operations with intermediate commits
- Batch processing with progress checkpoints

```sql
CREATE OR REPLACE PROCEDURE process_large_batch(
    batch_size_ INTEGER DEFAULT 1000
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_processed INTEGER := 0;
    v_row RECORD;
BEGIN
    FOR v_row IN 
        SELECT id FROM pending_items 
        WHERE processed_at IS NULL 
        LIMIT batch_size_
    LOOP
        -- Process item
        UPDATE pending_items 
        SET processed_at = CURRENT_TIMESTAMP 
        WHERE id = v_row.id;

        v_processed := v_processed + 1;

        -- Commit every 100 rows
        IF v_processed % 100 = 0 THEN
            COMMIT;
            RAISE NOTICE 'Processed % items', v_processed;
        END IF;
    END LOOP;

    COMMIT;
    RAISE NOTICE 'Completed: % items processed', v_processed;
END;
$$;
```

### Section 5.6 - Function Overloading

**AVOID function overloading**, especially with integer types:

```sql
-- PROHIBITED: Ambiguous overloading
CREATE FUNCTION get_item(id INTEGER) ...
CREATE FUNCTION get_item(id BIGINT) ...  -- Ambiguous!

-- CORRECT: Different names
CREATE FUNCTION get_item_by_id(id_ BIGINT) ...
CREATE FUNCTION get_item_by_sku(sku_ VARCHAR(50)) ...
```

### Section 5.7 - TDD Requirements for Functions and Procedures

**MANDATORY**: Every function and procedure MUST have a corresponding pgTAP test file written BEFORE or concurrently with the implementation.

**Minimum test coverage per function/procedure:**

| Test Category        | Required    | Example Assertion                                   |
| -------------------- | ----------- | --------------------------------------------------- |
| Existence            | YES         | `has_function('function_name')`                     |
| Signature            | YES         | `function_returns('schema', 'func', 'return_type')` |
| Happy path           | YES         | `results_eq()` or `is()` with valid inputs          |
| NULL handling        | YES         | Test behavior with NULL parameters                  |
| Edge cases           | YES         | Empty sets, boundary values, zero                   |
| Error conditions     | CONDITIONAL | `throws_ok()` for functions that raise exceptions   |
| Performance baseline | CONDITIONAL | `EXPLAIN ANALYZE` documented for complex queries    |

```sql
-- Example: Minimum TDD test file for a function
BEGIN;
SELECT plan(6);

-- RED phase: These tests define what the function MUST do
SELECT has_function('calculate_order_total', 
    'Function calculate_order_total should exist');

SELECT function_returns('public', 'calculate_order_total', 'numeric',
    'calculate_order_total should return NUMERIC');

SELECT is(
    calculate_order_total(100.00, 0.08),
    108.00::NUMERIC,
    'Should apply 8% tax to base amount'
);

SELECT is(
    calculate_order_total(0.00, 0.08),
    0.00::NUMERIC,
    'Should return 0 for zero amount'
);

SELECT is(
    calculate_order_total(NULL, 0.08),
    NULL::NUMERIC,
    'Should return NULL when amount is NULL'
);

SELECT is(
    calculate_order_total(100.00, NULL),
    NULL::NUMERIC,
    'Should return NULL when tax rate is NULL'
);

SELECT * FROM finish();
ROLLBACK;
```

---

## Article VI: Views and Materialized Views

### Section 6.1 - View Types and Use Cases

| Type              | Characteristics              | Use Cases                                 |
| ----------------- | ---------------------------- | ----------------------------------------- |
| Simple View       | Single table, no aggregation | Column hiding, row filtering, security    |
| Complex View      | Joins, aggregations          | Reporting, dashboards                     |
| Materialized View | Physically stored            | Expensive aggregations, caching           |
| Updatable View    | Supports DML                 | Simplified interface to complex structure |

### Section 6.2 - View Design Guidelines

1. **Naming**: Prefix with `v_` for views, `mv_` for materialized views
2. **Documentation**: Add `COMMENT ON VIEW` explaining purpose
3. **Performance**: Ensure supporting indexes exist on base tables
4. **Security**: Use views to implement row-level security

### Section 6.3 - Materialized View Patterns

```sql
-- Create materialized view with appropriate indexes
CREATE MATERIALIZED VIEW mv_monthly_sales AS
SELECT 
    DATE_TRUNC('month', order_date) AS month,
    product_category,
    SUM(quantity) AS total_quantity,
    SUM(amount) AS total_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
GROUP BY 1, 2
WITH DATA;

-- Create index for common query patterns
CREATE INDEX mv_monthly_sales_month_idx 
ON mv_monthly_sales (month);

-- Refresh strategy
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_sales;
```

### Section 6.4 - Updatable Views

Use `WITH CHECK OPTION` for data integrity:

```sql
CREATE VIEW v_active_customers AS
SELECT id, name, email, phone, is_active
FROM customers
WHERE is_active = TRUE
  AND deleted_at IS NULL
WITH CHECK OPTION;

-- Prevents inserting/updating rows that don't match WHERE clause
```

---

## Article VII: Indexing Strategy

### Section 7.1 - Index Type Selection Matrix

| Index Type       | Operators                                             | Best For                          |
| ---------------- | ----------------------------------------------------- | --------------------------------- |
| B-tree (default) | `=`, `<`, `>`, `<=`, `>=`, `BETWEEN`, `IN`, `IS NULL` | Most queries                      |
| Hash             | `=` only                                              | Exact match lookups               |
| GIN              | `@>`, `<@`, `?`, `?                                   | `, `?&`, `&&`                     |
| GiST             | Geometric, range, full-text                           | Spatial, proximity, exclusion     |
| BRIN             | `<`, `<=`, `=`, `>=`, `>`                             | Large sequential/time-series data |
| SP-GiST          | Various                                               | Hierarchical, clustered data      |

### Section 7.2 - Indexing Best Practices

1. **Create indexes for all query WHERE clauses** used in online queries

2. **Composite indexes**: Order columns by selectivity (most selective first)

3. **Partial indexes**: Use for selective conditions
   
   ```sql
   CREATE INDEX orders_pending_idx ON orders (created_at)
   WHERE status = 'pending';
   ```

4. **Expression indexes**: Index computed values
   
   ```sql
   CREATE INDEX customers_lower_email_idx ON customers (LOWER(email));
   ```

5. **Covering indexes**: Include columns to enable index-only scans
   
   ```sql
   CREATE INDEX orders_covering_idx ON orders (customer_id) 
   INCLUDE (order_date, status);
   ```

### Section 7.3 - Index Anti-Patterns

**AVOID:**

1. Indexes on low-cardinality columns (boolean, status with few values)
2. Too many indexes on frequently-updated tables
3. Redundant indexes (subset of existing composite index)
4. Indexes without monitoring usage

### Section 7.4 - Index Maintenance

1. Monitor index usage with `pg_stat_user_indexes`
2. Identify and drop unused indexes
3. Rebuild bloated indexes with `REINDEX CONCURRENTLY`
4. Run `ANALYZE` after bulk operations

---

## Article VIII: Error Handling

### Section 8.1 - Exception Handling Structure

```sql
CREATE OR REPLACE FUNCTION safe_operation(param_ INTEGER)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_result BOOLEAN := FALSE;
BEGIN
    -- Main logic
    PERFORM some_operation(param_);
    v_result := TRUE;

    RETURN v_result;

EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Duplicate entry for param %', param_;
        RETURN FALSE;
    WHEN foreign_key_violation THEN
        RAISE WARNING 'Referenced record not found for param %', param_;
        RETURN FALSE;
    WHEN OTHERS THEN
        RAISE WARNING 'Unexpected error: % - %', SQLSTATE, SQLERRM;
        RETURN FALSE;
END;
$$;
```

### Section 8.2 - Exception Handling Rules

1. **PREFER specific exceptions** over `WHEN OTHERS`
2. **Log errors** with appropriate severity (NOTICE, WARNING, EXCEPTION)
3. **Include context** in error messages (parameter values, state)
4. **Minimize exception blocks**: They create savepoints (performance cost)
5. **Never swallow errors silently**: Always log or re-raise
6. **MANDATORY**: Test exception paths with `throws_ok()` or `lives_ok()` in pgTAP

### Section 8.3 - RAISE Statement Levels

| Level       | Purpose             | Behavior                |
| ----------- | ------------------- | ----------------------- |
| `DEBUG`     | Detailed debugging  | Configurable visibility |
| `LOG`       | Server-side logging | Configurable visibility |
| `INFO`      | Informational       | Always visible          |
| `NOTICE`    | Notable events      | Always visible          |
| `WARNING`   | Potential issues    | Always visible          |
| `EXCEPTION` | Errors              | Aborts transaction      |

### Section 8.4 - Performance Consideration

**WARNING**: Exception blocks create implicit savepoints.

```sql
-- INEFFICIENT: Exception block in loop creates many savepoints
FOR i IN 1..1000 LOOP
    BEGIN
        INSERT INTO t VALUES (i);
    EXCEPTION WHEN unique_violation THEN
        NULL;  -- Each iteration creates savepoint!
    END;
END LOOP;

-- BETTER: Handle outside loop or use ON CONFLICT
INSERT INTO t 
SELECT generate_series(1, 1000)
ON CONFLICT DO NOTHING;
```

### Section 8.5 - Illegal ROLLBACK in Exception Handlers

**PROHIBITION**: Never issue `ROLLBACK` inside a PL/pgSQL `EXCEPTION` block within a function. PostgreSQL automatically rolls back to an implicit savepoint when entering an exception handler. An explicit `ROLLBACK` will either fail or produce undefined behavior.

```sql
-- PROHIBITED: Illegal ROLLBACK in exception handler
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;  -- ILLEGAL! Transaction state is already rolled back to savepoint
        RAISE WARNING 'Error: %', SQLERRM;

-- CORRECT: Let PostgreSQL handle the rollback
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Error: % - %', SQLSTATE, SQLERRM;
        -- PostgreSQL has already rolled back to the implicit savepoint
```

**Note**: This is a P0 critical issue identified across 100% of GCP DMS converted by gemini procedures in the Perseus migration. GCP DMS (gemini) routinely generates illegal ROLLBACK statements inside exception handlers.

---

## Article IX: Foreign Data Wrappers (FDW)

### Section 9.1 - FDW Setup Pattern

```sql
-- 1. Enable extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- 2. Create foreign server
CREATE SERVER remote_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'remote-host.example.com',
    port '5432',
    dbname 'remote_database',
    fetch_size '10000',           -- Tune based on network latency
    use_remote_estimate 'true'    -- Use remote statistics
);

-- 3. Create user mapping
CREATE USER MAPPING FOR local_user
SERVER remote_server
OPTIONS (
    user 'remote_user',
    password 'secure_password'    -- Consider using .pgpass
);

-- 4. Import schema (preferred over manual creation)
IMPORT FOREIGN SCHEMA remote_schema
FROM SERVER remote_server
INTO local_schema;
```

### Section 9.2 - FDW Performance Optimization

| Parameter             | Default | Recommendation | Purpose                       |
| --------------------- | ------- | -------------- | ----------------------------- |
| `fetch_size`          | 100     | 1000-10000     | Rows per network round trip   |
| `use_remote_estimate` | false   | true           | Use remote server statistics  |
| `extensions`          | empty   | list needed    | Push down extension functions |

### Section 9.3 - FDW Query Optimization

1. **Push down WHERE clauses**: Ensure conditions use IMMUTABLE operators
2. **Use CTEs for filtering**: Pre-filter before joining with local tables
3. **Run ANALYZE on foreign tables**: Maintain local statistics
4. **Materialize for heavy use**: Cache frequently-accessed remote data

```sql
-- OPTIMIZED: Filter remote data in CTE before local join
WITH remote_filtered AS (
    SELECT id, data
    FROM remote_table
    WHERE created_at > CURRENT_DATE - INTERVAL '7 days'
)
SELECT l.*, r.data
FROM local_table l
JOIN remote_filtered r ON r.id = l.remote_id;
```

### Section 9.4 - FDW Caching Strategy

```sql
-- Materialized view for caching remote data
CREATE MATERIALIZED VIEW mv_remote_cache AS
SELECT * FROM remote_table
WHERE created_at > CURRENT_DATE - INTERVAL '30 days'
WITH DATA;

-- Create indexes on cached data
CREATE INDEX mv_remote_cache_id_idx ON mv_remote_cache (id);

-- Refresh strategy (schedule appropriately)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_remote_cache;
```

---

## Article X: Transaction Management

### Section 10.1 - Transaction Principles

1. **Keep transactions short**: Commit or rollback as soon as possible
2. **Avoid long-running transactions**: IDLE IN transactions > 10 min may be terminated
3. **Enable AutoCommit**: Prevent orphaned transactions
4. **Use connection pooling**: Access through pgbouncer (port 6432)

### Section 10.2 - Timeout Configuration

```sql
-- Set statement timeout (10ms for online, longer for batch)
SET statement_timeout = '10ms';        -- Online queries
SET statement_timeout = '5min';        -- Batch operations

-- Set lock timeout to avoid indefinite waits
SET lock_timeout = '3s';
```

### Section 10.3 - Advisory Locks for Hotspots

```sql
-- For high-concurrency access to same rows
SELECT pg_advisory_lock(hashtext('order_processing:' || order_id::text));
-- ... perform operations ...
SELECT pg_advisory_unlock(hashtext('order_processing:' || order_id::text));

-- Or use transaction-scoped locks (auto-release on commit/rollback)
SELECT pg_advisory_xact_lock(hashtext('order_processing:' || order_id::text));
```

---

## Article XI: Performance Optimization

### Section 11.1 - Query Analysis

**MANDATORY** for new code:

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT ... ;
```

Key metrics to verify:

- No unexpected sequential scans on large tables
- Index scans where expected
- Reasonable row estimates vs actual rows
- Acceptable buffer usage

### Section 11.2 - Bulk Load Optimization

```sql
-- For large data loads:
-- 1. Disable autovacuum temporarily
ALTER TABLE target_table SET (autovacuum_enabled = false);

-- 2. Increase work_mem for session
SET work_mem = '256MB';
SET maintenance_work_mem = '512MB';

-- 3. Use COPY instead of INSERT
COPY target_table FROM '/path/to/data.csv' WITH (FORMAT csv, HEADER);

-- 4. Create indexes after loading
CREATE INDEX ...;

-- 5. Analyze and re-enable autovacuum
ANALYZE target_table;
ALTER TABLE target_table SET (autovacuum_enabled = true);
```

### Section 11.3 - Partitioning Guidelines

Consider partitioning when:

- Single table exceeds 100 million rows
- Single table exceeds 10GB
- Time-series data with frequent range queries
- Need to efficiently archive old data

### Section 11.4 - Excessive LOWER() Anti-Pattern

**PROHIBITION**: Do not wrap columns in `LOWER()` unless case-insensitive comparison is explicitly required.

GCP DMS routinely adds unnecessary `LOWER()` calls during T-SQL to PL/pgSQL conversion. This causes approximately **39% performance degradation** by preventing index usage on the original column.

```sql
-- PROHIBITED: Unnecessary LOWER() (GCP DMS artifact)
WHERE LOWER(customer_name) = LOWER(p_name)

-- CORRECT: Direct comparison when column data is already lowercase
WHERE customer_name = p_name

-- CORRECT: LOWER() only when case-insensitive matching is a business requirement
-- AND a functional index exists:
CREATE INDEX customers_lower_name_idx ON customers (LOWER(name));
WHERE LOWER(name) = LOWER(p_name)
```

---

## Article XII: Code Organization and Documentation

### Section 12.1 - Object Comments

**MANDATORY**: All database objects must have comments:

```sql
COMMENT ON TABLE customers IS 'Customer master data with contact and billing information';
COMMENT ON COLUMN customers.is_active IS 'FALSE when customer churned or requested deletion';
COMMENT ON FUNCTION get_customer_by_id IS 'Retrieves customer by primary key, returns NULL if not found';
```

### Section 12.2 - Code Formatting Standards

1. **Keywords**: UPPERCASE (`SELECT`, `FROM`, `WHERE`, `JOIN`)
2. **Identifiers**: lowercase (`customers`, `order_date`)
3. **Indentation**: 4 spaces (no tabs)
4. **Line length**: Maximum 120 characters
5. **Column lists**: One column per line for readability
6. **Commas**: Leading comma style for easy line manipulation

```sql
SELECT 
    c.id
    , c.name
    , c.email
    , o.order_date
    , o.total_amount
FROM customers c
JOIN orders o 
    ON o.customer_id = c.id
WHERE c.is_active = TRUE
    AND o.order_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY o.order_date DESC;
```

### Section 12.3 - Change Management

1. **No DDL in application code**: Schema changes through migration scripts only
2. **CONCURRENTLY for production**: Use `CREATE INDEX CONCURRENTLY`, `REINDEX CONCURRENTLY`
3. **Rollback scripts**: Every schema change must have corresponding rollback
4. **Version control**: All database code in Git repository

---

## Article XIII: Security Standards

### Section 13.1 - Principle of Least Privilege

1. Application users get minimum required permissions
2. Use roles for permission grouping
3. Never use superuser in applications
4. Grant permissions on schemas, not databases

### Section 13.2 - SQL Injection Prevention

1. **ALWAYS use parameterized queries**
2. **NEVER concatenate user input into SQL strings**
3. Use `quote_ident()` for dynamic identifiers
4. Use `quote_literal()` for dynamic literals

```sql
-- SAFE: Parameterized
EXECUTE format('SELECT * FROM %I WHERE id = $1', table_name) USING user_id;

-- DANGEROUS: String concatenation
EXECUTE 'SELECT * FROM ' || table_name || ' WHERE id = ' || user_id;  -- PROHIBITED!
```

---

## Article XIV: Migration-Specific Standards (SQL Server → PostgreSQL)

### Section 14.1 - Temporary Table Patterns

SQL Server temporary tables must be converted to PostgreSQL patterns:

```sql
-- SQL Server: CREATE TABLE #temp ...
-- PostgreSQL: CREATE TEMPORARY TABLE tmp_ ...

CREATE TEMPORARY TABLE tmp_processing (
    id BIGINT,
    data TEXT
) ON COMMIT DROP;  -- or ON COMMIT DELETE ROWS
```

**CRITICAL**: GCP DMS often generates `SELECT INTO` for temp table creation. This is a P0 issue. Always use explicit `CREATE TEMPORARY TABLE` followed by `INSERT INTO`.

### Section 14.2 - Transaction Control Replacement

```sql
-- SQL Server: BEGIN TRANSACTION / COMMIT / ROLLBACK
-- PostgreSQL: BEGIN / COMMIT / ROLLBACK (or use procedures)

-- In procedures, you can use:
BEGIN;
    -- statements
COMMIT;  -- or ROLLBACK;
```

### Section 14.3 - IDENTITY Column Conversion

```sql
-- SQL Server: IDENTITY(1,1)
-- PostgreSQL: GENERATED ALWAYS AS IDENTITY

CREATE TABLE products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ...
);
```

### Section 14.4 - String Function Mapping

| SQL Server           | PostgreSQL              |
| -------------------- | ----------------------- |
| `ISNULL(a, b)`       | `COALESCE(a, b)`        |
| `LEN(s)`             | `LENGTH(s)`             |
| `GETDATE()`          | `CURRENT_TIMESTAMP`     |
| `DATEADD(...)`       | `+ INTERVAL '...'`      |
| `DATEDIFF(...)`      | Arithmetic or `AGE()`   |
| `CONVERT(type, val)` | `val::type` or `CAST()` |
| `TOP n`              | `LIMIT n`               |

### Section 14.5 - Linked Server to FDW Conversion

Replace SQL Server linked server (OPENQUERY) with postgres_fdw:

```sql
-- SQL Server:
-- SELECT * FROM OPENQUERY(LinkedServer, 'SELECT * FROM remote_table')

-- PostgreSQL:
SELECT * FROM fdw_schema.remote_table;
-- (after proper FDW setup as per Article IX)
```

---

## PART II: TEST-DRIVEN DEVELOPMENT STANDARDS

---

## Article XV: TDD Mandate and Core Principles

### Section 15.1 - The TDD Constitutional Mandate

**Test-Driven Development is MANDATORY for all database code in the Perseus project.**

This mandate applies to:

- All new functions and procedures
- All migrated stored procedures (SQL Server → PostgreSQL)
- All refactored or optimized existing code
- All views and materialized views with business logic
- All triggers
- All constraint definitions requiring validation

**Exemptions** (require written DBA approval):

- Pure DDL scripts (CREATE TABLE with no logic)
- One-time data migration scripts
- Exploratory spike code (must be replaced with TDD code before production)

### Section 15.2 - The Red-Green-Refactor Cycle

All code development SHALL follow the Red-Green-Refactor (RGR) cycle:

**RED — Write a failing test.** Write a pgTAP test for behavior that does not yet exist. Run the test and confirm it fails. This phase forces design thinking: you define what the code must do before writing it. The test defines the interface, the expected behavior, and the success criteria.

**GREEN — Make it pass with minimum code.** Write the absolute minimum PostgreSQL code needed to make the failing test pass. Elegance is irrelevant at this stage — effectiveness is the only goal. Get the tests green as fast as possible.

**REFACTOR — Clean up.** Improve the code's structure without changing its behavior. Eliminate duplication, improve naming, optimize queries, apply Constitution standards. The passing tests serve as your safety net.

```
┌─────────────────────────────────────────────────┐
│              RED-GREEN-REFACTOR CYCLE            │
│                                                  │
│    ┌───────┐    ┌───────┐    ┌──────────┐       │
│    │  RED  │───▶│ GREEN │───▶│ REFACTOR │──┐    │
│    │ Write │    │ Make  │    │  Clean   │  │    │
│    │ Test  │    │ Pass  │    │  Code    │  │    │
│    └───────┘    └───────┘    └──────────┘  │    │
│        ▲                                    │    │
│        └────────────────────────────────────┘    │
│                                                  │
│    Tests define behavior → Code satisfies tests  │
│    Tests protect refactoring → Code stays clean   │
└─────────────────────────────────────────────────┘
```

### Section 15.3 - The Three Laws of TDD (Adapted for Database Development)

1. **You SHALL NOT write any production SQL unless it is to make a failing pgTAP test pass.**
2. **You SHALL NOT write any more of a pgTAP test than is sufficient to fail** — and missing objects are failures.
3. **You SHALL NOT write any more production SQL than is sufficient to pass the one failing pgTAP test.**

### Section 15.4 - Baby Steps and YAGNI

**Baby steps** means making the smallest possible incremental change at each cycle. For database development:

- Test one assertion at a time
- Implement one behavior at a time
- Refactor one concern at a time

**YAGNI (You Ain't Gonna Need It)** prevents speculative features:

- Do not add columns "just in case"
- Do not add function parameters for future requirements
- Do not create indexes without query evidence
- The test defines exactly what is needed — everything else is unnecessary

### Section 15.5 - What TDD Is NOT

To prevent misapplication:

1. **TDD is NOT writing all tests first.** You write ONE test at a time.
2. **TDD is NOT a replacement for QA.** It does not cover performance testing, security audits, or exploratory testing.
3. **TDD is NOT unit testing after the fact.** Tests written after implementation do not constitute TDD.
4. **TDD does NOT mean skipping design.** Architecture decisions still happen — TDD validates and refines them.
5. **TDD does NOT guarantee bug-free code.** It increases confidence and catches defects early, but cannot prove absence of all bugs.

---

## Article XVI: pgTAP — Mandatory Testing Framework

### Section 16.1 - Framework Requirement

**pgTAP is the MANDATORY testing framework** for all PostgreSQL database testing in the Perseus project.

```sql
-- Installation (required on all development and test environments)
CREATE EXTENSION IF NOT EXISTS pgtap;
```

### Section 16.2 - Test File Structure

Every pgTAP test file MUST follow this structure:

```sql
-- =============================================================================
-- Test: test_<object_name>.sql
-- Object: <schema>.<object_name>
-- Author: Pierre Ribeiro + Claude
-- Created: YYYY-MM-DD
-- Constitution: v2.0 — Article XVI compliance
-- =============================================================================

BEGIN;

SELECT plan(N);  -- Always declare exact test count

-- ─── SCHEMA ASSERTIONS ───
-- Verify the object exists with correct structure

-- ─── HAPPY PATH ASSERTIONS ───
-- Test normal expected behavior

-- ─── EDGE CASE ASSERTIONS ───
-- Test NULL, empty, zero, boundary values

-- ─── ERROR CONDITION ASSERTIONS ───
-- Test that errors are raised correctly

-- ─── CLEANUP AND FINISH ───
SELECT * FROM finish();

ROLLBACK;  -- Always rollback — leave no trace
```

### Section 16.3 - Core pgTAP Assertions for Perseus

**Schema assertions (verify object structure):**

| Assertion                          | Purpose                        |
| ---------------------------------- | ------------------------------ |
| `has_table(schema, table)`         | Table exists                   |
| `has_column(table, column)`        | Column exists                  |
| `col_type_is(table, column, type)` | Column has correct type        |
| `col_is_pk(table, column)`         | Column is primary key          |
| `col_not_null(table, column)`      | Column has NOT NULL constraint |
| `has_function(function_name)`      | Function exists                |
| `has_index(table, index_name)`     | Index exists                   |
| `has_trigger(table, trigger_name)` | Trigger exists                 |
| `has_fk(table, fk_name)`           | Foreign key exists             |

**Behavioral assertions (verify logic):**

| Assertion                                     | Purpose                            |
| --------------------------------------------- | ---------------------------------- |
| `is(got, expected, description)`              | Equality check                     |
| `isnt(got, unexpected, description)`          | Inequality check                   |
| `ok(boolean, description)`                    | Boolean truth                      |
| `results_eq(sql, sql, description)`           | Query result comparison            |
| `set_eq(sql, sql, description)`               | Set comparison (order-independent) |
| `bag_eq(sql, sql, description)`               | Bag comparison (duplicates matter) |
| `throws_ok(sql, errcode, description)`        | Exception verification             |
| `lives_ok(sql, description)`                  | No exception verification          |
| `performs_ok(sql, milliseconds, description)` | Performance threshold              |

### Section 16.4 - Transaction Isolation Rule

**MANDATORY**: All tests run inside `BEGIN` / `ROLLBACK` blocks:

```sql
BEGIN;
SELECT plan(3);

-- Setup test data
INSERT INTO customers (name, email) VALUES ('Test User', 'test@example.com');

-- Run assertions
SELECT is(
    get_customer_by_email('test@example.com'),
    'Test User',
    'Should find customer by email'
);

SELECT * FROM finish();
ROLLBACK;  -- ALL changes undone — database is pristine
```

**Critical limitation**: Procedures that contain internal `COMMIT` or `ROLLBACK` cannot be tested inside this wrapper. For such procedures, use one of these strategies:

1. **Extract testable logic** into functions that CAN be tested in isolation
2. **Use a dedicated test database** that can be reset between test runs
3. **Test observable side effects** after procedure execution in a separate transaction

### Section 16.5 - Test Execution

```bash
# Run single test file
pg_prove -d perseus_test -v tests/test_reconcile_mupstream.sql

# Run all tests in directory
pg_prove -d perseus_test -v tests/

# Run with TAP output for CI integration
pg_prove -d perseus_test --formatter TAP tests/
```

---

## Article XVII: TDD Workflow for Database Migrations

### Section 17.1 - Migration TDD Workflow

For every SQL Server → PostgreSQL procedure migration, the following TDD workflow is MANDATORY:

```
┌──────────────────────────────────────────────────────────────┐
│              MIGRATION TDD WORKFLOW                          │
│                                                              │
│  1. ANALYZE                                                  │
│     └─ Read original T-SQL + GCP DMS output                  │
│     └─ Identify P0/P1/P2 issues                              │
│     └─ Define expected behaviors as test specifications      │
│                                                              │
│  2. RED                                                      │
│     └─ Write pgTAP tests for ALL expected behaviors          │
│     └─ Include schema tests (function exists, returns type)  │
│     └─ Include behavioral tests (happy path, edge cases)     │
│     └─ Run tests — ALL must FAIL (object doesn't exist yet)  │
│                                                              │
│  3. GREEN                                                    │
│     └─ Write the corrected PostgreSQL procedure              │
│     └─ Apply P0 fixes from analysis                          │
│     └─ Apply Constitution standards                          │
│     └─ Run tests — ALL must PASS                             │
│                                                              │
│  4. REFACTOR                                                 │
│     └─ Optimize P1 issues                                    │
│     └─ Apply P2 enhancements                                 │
│     └─ Run tests after EACH change — must stay GREEN         │
│                                                              │
│  5. REVIEW                                                   │
│     └─ Verify test coverage meets Constitution requirements  │
│     └─ Verify code quality score ≥ 7.0                       │
│     └─ Approve or request revision                           │
└──────────────────────────────────────────────────────────────┘
```

### Section 17.2 - Equivalence Testing for Migrations

When migrating from SQL Server, tests MUST verify behavioral equivalence:

```sql
-- Example: Testing that migrated function produces same results as SQL Server original
BEGIN;
SELECT plan(4);

-- Test 1: Same happy-path result
SELECT is(
    reconcile_mupstream(1001, 'ACTIVE'),
    TRUE,
    'reconcile_mupstream should return TRUE for active upstream with valid ID (matches SQL Server behavior)'
);

-- Test 2: Same NULL handling
SELECT is(
    reconcile_mupstream(NULL, 'ACTIVE'),
    NULL,
    'reconcile_mupstream should return NULL for NULL ID (matches SQL Server ISNULL behavior)'
);

-- Test 3: Same error behavior
SELECT throws_ok(
    $$SELECT reconcile_mupstream(-1, 'INVALID')$$,
    'P0001',
    'reconcile_mupstream should raise exception for invalid status'
);

-- Test 4: Same edge case
SELECT is(
    reconcile_mupstream(1001, NULL),
    FALSE,
    'reconcile_mupstream should return FALSE for NULL status'
);

SELECT * FROM finish();
ROLLBACK;
```

### Section 17.3 - Test Coverage Requirements for Migrated Objects

| Object Type                   | Minimum Test Count | Required Categories                                         |
| ----------------------------- | ------------------ | ----------------------------------------------------------- |
| Simple function (≤ 20 lines)  | 5                  | Existence, signature, happy path, NULL, edge case           |
| Complex function (> 20 lines) | 10+                | All above + error paths, boundary values                    |
| Stored procedure              | 8+                 | All above + transaction behavior, side effects              |
| View                          | 4+                 | Existence, column structure, expected data, empty source    |
| Trigger                       | 6+                 | Existence, fire-on-insert, fire-on-update, prevented action |
| Index                         | 2+                 | Existence, usage verification via EXPLAIN                   |

---

## Article XVIII: AI Agent TDD Enforcement

### Section 18.1 - Context Over Procedure

Based on empirical evidence from the TDAD (Test-Driven Agentic Development) research:

**AI agents do not need elaborate TDD instructions. They need clear, verifiable test targets.**

Providing specific test targets produces better results than procedural TDD prompts. The enforcement model for Perseus AI agents (Claude Code, Claude Desktop) is:

1. **Provide the test file** — Tell the agent which tests must pass
2. **Provide the Constitution** — Standards the code must meet
3. **Let the agent implement** — Minimum code to pass tests, then refactor
4. **Verify results** — Tests pass, Constitution compliance confirmed

### Section 18.2 - AI Agent TDD Rules

When any AI agent writes PostgreSQL code for Perseus:

1. **Never write implementation code without a failing test.** If asked to create a function, write the test first.
2. **Read test output to confirm failure before implementing.** The test must fail for the right reason (missing object, not syntax error in test).
3. **Write the simplest code that passes the current test.** Do not anticipate future requirements.
4. **Refactor only after tests pass.** Never refactor while tests are red.
5. **When modifying existing functions**, ensure a pgTAP test exists first. Create one if none exists, then modify, then verify.
6. **Commit on green, revert on red.** If tests pass after a change, commit. If any test fails, revert to the last known-good state.

### Section 18.3 - Context Isolation for AI Agents

When AI agents operate the TDD cycle, context isolation between phases prevents "context pollution":

| Phase                  | Agent Focus              | Context Available                           | Context NOT Available                  |
| ---------------------- | ------------------------ | ------------------------------------------- | -------------------------------------- |
| RED (Test Writing)     | Define expected behavior | Requirements, Constitution, existing schema | Implementation ideas, code snippets    |
| GREEN (Implementation) | Make tests pass          | Failing test output, Constitution           | Test rationale, alternative approaches |
| REFACTOR               | Clean structure          | Passing test suite, Constitution            | Implementation history, dead ends      |

### Section 18.4 - Test-First Enforcement for Claude Code

Claude Code sessions working on Perseus MUST:

```
# Before writing any function/procedure:
1. Create test file: tests/test_<object_name>.sql
2. Write schema assertions (has_function, returns type)
3. Write behavioral assertions (happy path, edge cases)
4. Run tests — confirm RED (all fail)
5. ONLY THEN write the implementation
6. Run tests — confirm GREEN (all pass)
7. Refactor — run tests after each change
8. Commit when GREEN
```

---

## PART III: COMPLIANCE AND QUALITY GATES

---

## Article XIX: Compliance and Enforcement

### Section 19.1 - Code Review Requirements

All database code changes require:

1. Self-review against this Constitution
2. pgTAP test suite passes (100% green)
3. Technical Lead review
4. DBA review for production deployment
5. EXPLAIN ANALYZE results for new queries

### Section 19.2 - Quality Score Dimensions

Code quality assessed across **six dimensions** (updated from v1.0 to include testability):

| Dimension          | Weight  | Criteria                                               |
| ------------------ | ------- | ------------------------------------------------------ |
| Syntax Correctness | 15%     | Valid PostgreSQL 17 syntax, no errors                  |
| Logic Preservation | 25%     | Business logic identical to original                   |
| Performance        | 15%     | Within 20% of SQL Server baseline                      |
| Maintainability    | 15%     | Readable, documented, follows Constitution             |
| Security           | 15%     | No injection risks, proper permissions                 |
| **Test Coverage**  | **15%** | **pgTAP tests exist, pass, cover required categories** |

**Minimum passing score: 7.0/10 overall, no dimension below 6.0**

### Section 19.3 - Test Coverage Scoring Rubric

| Score | Criteria                                                                    |
| ----- | --------------------------------------------------------------------------- |
| 10    | All required categories covered + performance tests + exceeds minimum count |
| 8-9   | All required categories covered, meets minimum count                        |
| 6-7   | Most categories covered, missing 1-2 edge cases                             |
| 4-5   | Only happy path tested, missing error/NULL/edge cases                       |
| 0-3   | No tests, or tests written after implementation without TDD cycle           |

### Section 19.4 - Violation Handling

| Severity      | Action Required                 |
| ------------- | ------------------------------- |
| P0 - Critical | Block deployment, immediate fix |
| P1 - High     | Fix before production           |
| P2 - Medium   | Fix in next sprint              |
| P3 - Low      | Track for future improvement    |

**TDD-specific violations:**

| Violation                                | Severity | Action                                    |
| ---------------------------------------- | -------- | ----------------------------------------- |
| Code deployed without tests              | P0       | Block deployment, write tests immediately |
| Tests written after implementation       | P1       | Document, refactor to TDD in next sprint  |
| Test file exists but doesn't pass        | P0       | Block deployment, fix immediately         |
| Insufficient test coverage (<6.0 score)  | P1       | Add missing test categories before deploy |
| Tests don't cover NULL handling          | P1       | Add NULL tests before deploy              |
| No equivalence tests for migrated object | P1       | Add equivalence tests before deploy       |

---

## Article XX: Brownfield Migration Compatibility

### Section 20.1 - Context and Scope

The Perseus Database Migration is a **brownfield project** migrating from SQL Server to PostgreSQL. This article addresses naming convention transitions for existing objects.

**Key Findings from Application Team Analysis (2026-01):**

| Aspect                         | Finding                    | Implication                |
| ------------------------------ | -------------------------- | -------------------------- |
| Procedure calls in application | None identified            | Safe to rename             |
| Database jobs                  | 6 jobs with SP references  | Will be refactored         |
| Migration scripts              | Occasional SP calls        | Communicate changes        |
| Table/column naming            | Already snake_case         | No conversion needed       |
| Case sensitivity               | Not present in application | Safe to lowercase          |
| ORM behavior                   | Handles column mapping     | No ordinal position issues |

### Section 20.2 - Naming Convention Transition Strategy

**APPROVED APPROACH**: Convert all PascalCase names to snake_case.

The dual-layer compatibility approach is **NOT REQUIRED** because:

1. No stored procedure calls exist in the application codebase
2. Table and column names are already snake_case compliant
3. The application layer has no case-sensitive dependencies
4. Job references will be refactored as part of migration

### Section 20.3 - PascalCase to snake_case Conversion Rules

When converting SQL Server object names:

```
SQL Server (PascalCase)     →  PostgreSQL (snake_case)
─────────────────────────────────────────────────────
GetMaterialByRunProperties  →  get_material_by_run_properties
ReconcileMUpstream          →  reconcile_mupstream
sp_MoveNode                 →  move_node (drop sp_ prefix)
fn_CalculateTotal           →  calculate_total (drop fn_ prefix)
tbl_Customers               →  customers (drop tbl_ prefix)
vw_ActiveOrders             →  v_active_orders (standardize prefix)
```

**Conversion Algorithm:**

1. Remove Hungarian notation prefixes (`sp_`, `fn_`, `tbl_`, `vw_`)
2. Insert underscore before each uppercase letter
3. Convert entire string to lowercase
4. Apply standard PostgreSQL prefixes where applicable (`v_`, `mv_`, `tmp_`)

### Section 20.4 - Coordination Requirements

**MANDATORY** before deploying renamed objects:

| Stakeholder       | Action Required             | Timing                    |
| ----------------- | --------------------------- | ------------------------- |
| DBA Team          | Document all name changes   | Before deployment         |
| Dev Team          | Update 6 database jobs      | Coordinated deployment    |
| Migration Scripts | Update any SP references    | Before next migration run |
| Documentation     | Update schema documentation | Post-deployment           |

### Section 20.5 - Objects Exempt from Renaming

The following objects MAY retain original names if renaming creates unacceptable risk:

1. **External system interfaces** — Objects called by systems outside Perseus control
2. **Third-party integrations** — APIs or connectors with hardcoded references
3. **Audit/compliance requirements** — Where name traceability is legally required

**Exemption requires**: Written approval from Project Lead and DBA with documented justification.

### Section 20.6 - Tracking and Documentation

**MANDATORY** for all renamed objects:

1. **Maintain mapping table** in project documentation
2. **Git commit message format**: Conventional commit with rename details
3. **Update GCP DMS analysis documents** with new names

### Section 20.7 - Validation Checklist

Before deploying any renamed object:

- [ ] New name follows snake_case convention (Article I)
- [ ] No SQL reserved words in new name
- [ ] pgTAP tests updated with new name
- [ ] Dev team notified of change
- [ ] Job references identified and update scheduled
- [ ] Migration scripts checked for references
- [ ] Documentation updated with name mapping
- [ ] Rollback script prepared

---

## Article XXI: Migration-Specific Quality Gates

### Section 21.1 - Pre-Conversion Checklist

Before converting any SQL Server object:

- [ ] Original T-SQL source code obtained
- [ ] GCP DMS conversion output reviewed
- [ ] Dependencies identified (callers and callees)
- [ ] Test data/scenarios documented
- [ ] Expected behavior baseline established
- [ ] **pgTAP test specifications written (RED phase)**

### Section 21.2 - Conversion Quality Scoring

All converted objects are scored on 6 dimensions (see Section 19.2):

| Dimension          | Weight | Criteria                                           |
| ------------------ | ------ | -------------------------------------------------- |
| Syntax Correctness | 15%    | Valid PostgreSQL 17 syntax, no errors              |
| Logic Preservation | 25%    | Business logic identical to original               |
| Performance        | 15%    | Within 20% of SQL Server baseline                  |
| Maintainability    | 15%    | Readable, documented, follows Constitution         |
| Security           | 15%    | No injection risks, proper permissions             |
| Test Coverage      | 15%    | pgTAP tests exist, pass, cover required categories |

**Scoring Scale:**

- 10: Exceptional - Exceeds requirements
- 8-9: Good - Meets all requirements
- 6-7: Acceptable - Minor issues, can deploy
- 4-5: Needs Work - Significant issues, fix before deploy
- 0-3: Critical - Major problems, block deployment

**Passing Threshold:**

- Overall score: ≥ 7.0
- No individual dimension: < 6.0

### Section 21.3 - Issue Classification

| Priority      | Description                                                            | Action                | SLA                |
| ------------- | ---------------------------------------------------------------------- | --------------------- | ------------------ |
| P0 - Critical | Blocks execution, data corruption risk, missing tests                  | Immediate fix         | Before any testing |
| P1 - High     | Logic errors, performance degradation >50%, insufficient test coverage | Fix before deployment | Within sprint      |
| P2 - Medium   | Non-critical improvements, minor performance                           | Fix in next sprint    | Next sprint        |
| P3 - Low      | Style/convention suggestions                                           | Track for future      | Backlog            |

### Section 21.4 - Common SQL Server → PostgreSQL Issues

**P0 Issues (Always check):**

| Issue                       | SQL Server               | PostgreSQL Fix                     |
| --------------------------- | ------------------------ | ---------------------------------- |
| Temp table initialization   | `SELECT INTO #temp`      | `CREATE TEMP TABLE` + `INSERT`     |
| Transaction control         | `BEGIN TRAN`             | `BEGIN` (or use procedures)        |
| Identity insert             | `SET IDENTITY_INSERT ON` | `OVERRIDING SYSTEM VALUE`          |
| String concatenation        | `+` operator             | `\|\|` operator or `CONCAT()`      |
| Null comparison             | `= NULL`                 | `IS NULL`                          |
| Top N rows                  | `SELECT TOP n`           | `LIMIT n`                          |
| Conditional logic           | `IIF(cond, t, f)`        | `CASE WHEN cond THEN t ELSE f END` |
| Illegal ROLLBACK            | `ROLLBACK` in CATCH      | Remove — PG auto-handles           |
| Missing transaction control | Implicit in SQL Server   | Explicit `BEGIN`/`COMMIT` required |

**P1 Issues (Performance):**

| Issue             | SQL Server                 | PostgreSQL Fix                               |
| ----------------- | -------------------------- | -------------------------------------------- |
| NOLOCK hint       | `WITH (NOLOCK)`            | Remove (use appropriate isolation)           |
| Index hints       | `WITH (INDEX=...)`         | Remove (trust planner) or use `pg_hint_plan` |
| Excessive LOWER() | GCP DMS adds unnecessarily | Remove if column already lowercase           |
| Missing COALESCE  | NULL handling              | Add explicit NULL handling                   |

### Section 21.5 - Post-Conversion Validation

**MANDATORY** after conversion:

1. **Test validation**: All pgTAP tests pass (GREEN)
2. **Syntax validation**: Execute in PostgreSQL without errors
3. **Logic validation**: Compare output with SQL Server for same inputs
4. **Performance validation**: EXPLAIN ANALYZE, compare with baseline
5. **Edge case validation**: NULL handling, empty sets, boundary conditions

---

## PART IV: APPENDICES

---

## Appendix A: Quick Reference Card

```
NAMING:
- Tables: plural snake_case (customers)
- Views: v_name (v_active_customers)
- Mat Views: mv_name (mv_monthly_sales)
- Functions: verb_noun (get_customer_by_id)
- Indexes: table_column_suffix (_pkey, _key, _idx)
- Tests: test_object_name (test_get_customer_by_id.sql)

DATA TYPES:
- PKs: BIGINT GENERATED ALWAYS AS IDENTITY
- Strings: TEXT or VARCHAR(n)
- Timestamps: TIMESTAMPTZ (always UTC)
- JSON: JSONB (not JSON)

QUERIES:
- NO SELECT * in production
- EXISTS over IN for subqueries
- LIMIT 1 for existence checks
- CTEs over temp tables

FUNCTIONS:
- Always specify volatility (IMMUTABLE/STABLE/VOLATILE)
- No overloading with similar types
- Use RETURNING after DML
- Use ON CONFLICT for upserts

ERROR HANDLING:
- Specific exceptions over WHEN OTHERS
- Include context in error messages
- Minimize exception blocks (performance)
- NEVER ROLLBACK in exception handlers

FDW:
- fetch_size: 1000-10000
- use_remote_estimate: true
- ANALYZE foreign tables regularly
- Use CTEs to pre-filter remote data

TDD (NEW in v2.0):
- RED: Write failing pgTAP test FIRST
- GREEN: Minimum code to pass
- REFACTOR: Clean up, tests stay green
- Every function/procedure needs tests
- Tests run inside BEGIN/ROLLBACK
- Minimum 5 tests for simple functions
- Minimum 8+ tests for procedures
- Test NULLs, edge cases, errors
- No code without tests = P0 violation
```

---

## Appendix B: SQL Server to PostgreSQL Quick Reference

### B.1 - Data Type Mapping

| SQL Server         | PostgreSQL                 | Notes              |
| ------------------ | -------------------------- | ------------------ |
| `INT`              | `INTEGER`                  |                    |
| `BIGINT`           | `BIGINT`                   |                    |
| `SMALLINT`         | `SMALLINT`                 |                    |
| `TINYINT`          | `SMALLINT`                 | No TINYINT in PG   |
| `BIT`              | `BOOLEAN`                  |                    |
| `DECIMAL(p,s)`     | `NUMERIC(p,s)`             |                    |
| `MONEY`            | `NUMERIC(19,4)` or `MONEY` |                    |
| `FLOAT`            | `DOUBLE PRECISION`         |                    |
| `REAL`             | `REAL`                     |                    |
| `DATETIME`         | `TIMESTAMP`                |                    |
| `DATETIME2`        | `TIMESTAMP`                |                    |
| `DATETIMEOFFSET`   | `TIMESTAMPTZ`              |                    |
| `DATE`             | `DATE`                     |                    |
| `TIME`             | `TIME`                     |                    |
| `CHAR(n)`          | `CHAR(n)`                  | Avoid, use VARCHAR |
| `VARCHAR(n)`       | `VARCHAR(n)`               |                    |
| `VARCHAR(MAX)`     | `TEXT`                     |                    |
| `NVARCHAR(n)`      | `VARCHAR(n)`               | PG is UTF-8 native |
| `NVARCHAR(MAX)`    | `TEXT`                     |                    |
| `TEXT`             | `TEXT`                     |                    |
| `BINARY(n)`        | `BYTEA`                    |                    |
| `VARBINARY(n)`     | `BYTEA`                    |                    |
| `IMAGE`            | `BYTEA`                    |                    |
| `UNIQUEIDENTIFIER` | `UUID`                     |                    |
| `XML`              | `XML`                      |                    |
| `SQL_VARIANT`      | `JSONB` or specific type   | Case-by-case       |

### B.2 - Function Mapping

| SQL Server                   | PostgreSQL                                  | Notes          |
| ---------------------------- | ------------------------------------------- | -------------- |
| `GETDATE()`                  | `CURRENT_TIMESTAMP`                         |                |
| `GETUTCDATE()`               | `CURRENT_TIMESTAMP AT TIME ZONE 'UTC'`      |                |
| `SYSDATETIME()`              | `CLOCK_TIMESTAMP()`                         |                |
| `DATEADD(unit, n, date)`     | `date + INTERVAL 'n unit'`                  |                |
| `DATEDIFF(unit, start, end)` | `EXTRACT(unit FROM end - start)` or `AGE()` |                |
| `DATEPART(unit, date)`       | `EXTRACT(unit FROM date)`                   |                |
| `DATENAME(unit, date)`       | `TO_CHAR(date, format)`                     |                |
| `CONVERT(type, val)`         | `val::type` or `CAST(val AS type)`          |                |
| `CAST(val AS type)`          | `CAST(val AS type)`                         |                |
| `ISNULL(a, b)`               | `COALESCE(a, b)`                            |                |
| `NULLIF(a, b)`               | `NULLIF(a, b)`                              | Same           |
| `COALESCE(...)`              | `COALESCE(...)`                             | Same           |
| `IIF(cond, t, f)`            | `CASE WHEN cond THEN t ELSE f END`          |                |
| `CHOOSE(idx, v1, v2, ...)`   | `CASE idx WHEN 1 THEN v1 ... END`           |                |
| `LEN(s)`                     | `LENGTH(s)`                                 |                |
| `DATALENGTH(s)`              | `OCTET_LENGTH(s)`                           |                |
| `CHARINDEX(sub, str)`        | `POSITION(sub IN str)`                      |                |
| `PATINDEX(pat, str)`         | `REGEXP_INSTR(str, pat)` (PG 15+)           |                |
| `SUBSTRING(s, start, len)`   | `SUBSTRING(s FROM start FOR len)`           |                |
| `LEFT(s, n)`                 | `LEFT(s, n)`                                | Same           |
| `RIGHT(s, n)`                | `RIGHT(s, n)`                               | Same           |
| `LTRIM(s)`                   | `LTRIM(s)`                                  | Same           |
| `RTRIM(s)`                   | `RTRIM(s)`                                  | Same           |
| `TRIM(s)`                    | `TRIM(s)`                                   | Same           |
| `UPPER(s)`                   | `UPPER(s)`                                  | Same           |
| `LOWER(s)`                   | `LOWER(s)`                                  | Same           |
| `REPLACE(s, old, new)`       | `REPLACE(s, old, new)`                      | Same           |
| `STUFF(s, start, len, new)`  | `OVERLAY(s PLACING new FROM start FOR len)` |                |
| `REPLICATE(s, n)`            | `REPEAT(s, n)`                              |                |
| `SPACE(n)`                   | `REPEAT(' ', n)`                            |                |
| `REVERSE(s)`                 | `REVERSE(s)`                                | Same           |
| `STRING_AGG(col, sep)`       | `STRING_AGG(col, sep)`                      | Same (PG 9.0+) |
| `ABS(n)`                     | `ABS(n)`                                    | Same           |
| `CEILING(n)`                 | `CEILING(n)`                                | Same           |
| `FLOOR(n)`                   | `FLOOR(n)`                                  | Same           |
| `ROUND(n, d)`                | `ROUND(n, d)`                               | Same           |
| `POWER(base, exp)`           | `POWER(base, exp)`                          | Same           |
| `SQRT(n)`                    | `SQRT(n)`                                   | Same           |
| `SIGN(n)`                    | `SIGN(n)`                                   | Same           |
| `RAND()`                     | `RANDOM()`                                  |                |
| `NEWID()`                    | `gen_random_uuid()`                         |                |
| `ROW_NUMBER()`               | `ROW_NUMBER()`                              | Same           |
| `RANK()`                     | `RANK()`                                    | Same           |
| `DENSE_RANK()`               | `DENSE_RANK()`                              | Same           |
| `NTILE(n)`                   | `NTILE(n)`                                  | Same           |
| `LAG(col, n)`                | `LAG(col, n)`                               | Same           |
| `LEAD(col, n)`               | `LEAD(col, n)`                              | Same           |
| `FIRST_VALUE(col)`           | `FIRST_VALUE(col)`                          | Same           |
| `LAST_VALUE(col)`            | `LAST_VALUE(col)`                           | Same           |

### B.3 - Syntax Mapping

| SQL Server                     | PostgreSQL                                       |
| ------------------------------ | ------------------------------------------------ |
| `SELECT TOP n ...`             | `SELECT ... LIMIT n`                             |
| `SELECT TOP n PERCENT ...`     | Use window functions or subquery                 |
| `SELECT ... INTO #temp`        | `CREATE TEMP TABLE ... AS SELECT ...`            |
| `INSERT INTO ... SELECT ...`   | Same                                             |
| `UPDATE ... FROM ...`          | Same (PostgreSQL extension)                      |
| `DELETE ... FROM ... JOIN ...` | `DELETE FROM ... USING ...`                      |
| `MERGE INTO ...`               | `INSERT ... ON CONFLICT ...` or `MERGE` (PG 15+) |
| `BEGIN TRANSACTION`            | `BEGIN`                                          |
| `COMMIT TRANSACTION`           | `COMMIT`                                         |
| `ROLLBACK TRANSACTION`         | `ROLLBACK`                                       |
| `SAVE TRANSACTION name`        | `SAVEPOINT name`                                 |
| `ROLLBACK TO name`             | `ROLLBACK TO SAVEPOINT name`                     |
| `@@ROWCOUNT`                   | Use `GET DIAGNOSTICS` or `FOUND`                 |
| `@@IDENTITY`                   | `LASTVAL()` or `RETURNING`                       |
| `SCOPE_IDENTITY()`             | `CURRVAL(seq)` or `RETURNING`                    |
| `@@ERROR`                      | Use exception handling                           |
| `RAISERROR(...)`               | `RAISE EXCEPTION ...`                            |
| `PRINT ...`                    | `RAISE NOTICE ...`                               |
| `SET NOCOUNT ON`               | Not needed (no count messages by default)        |
| `IF ... BEGIN ... END`         | `IF ... THEN ... END IF`                         |
| `WHILE ... BEGIN ... END`      | `WHILE ... LOOP ... END LOOP`                    |
| `BREAK`                        | `EXIT`                                           |
| `CONTINUE`                     | `CONTINUE`                                       |
| `RETURN`                       | `RETURN`                                         |
| `TRY ... CATCH`                | `BEGIN ... EXCEPTION ... END`                    |
| `EXEC sp_name`                 | `CALL proc_name()` or `SELECT func_name()`       |

### B.4 - Linked Server to FDW Migration

| SQL Server                     | PostgreSQL                                            |
| ------------------------------ | ----------------------------------------------------- |
| `sp_addlinkedserver`           | `CREATE SERVER ... FOREIGN DATA WRAPPER postgres_fdw` |
| `sp_addlinkedsrvlogin`         | `CREATE USER MAPPING FOR ...`                         |
| `OPENQUERY(server, 'query')`   | Query foreign table directly                          |
| `server.database.schema.table` | `foreign_schema.table`                                |

---

## Appendix C: pgTAP Quick Reference Card

```
SETUP:
  CREATE EXTENSION IF NOT EXISTS pgtap;

TEST STRUCTURE:
  BEGIN;
  SELECT plan(N);      -- or no_plan();
  -- assertions here
  SELECT * FROM finish();
  ROLLBACK;

SCHEMA ASSERTIONS:
  has_table(schema, table, description)
  has_column(table, column, description)
  col_type_is(table, column, type, description)
  col_is_pk(table, column, description)
  col_not_null(table, column, description)
  col_has_default(table, column, description)
  has_function(function, description)
  has_function(function, args[], description)
  function_returns(schema, function, type, description)
  has_index(table, index, description)
  has_trigger(table, trigger, description)
  has_fk(table, description)
  has_check(table, description)
  has_unique(table, description)

BEHAVIORAL ASSERTIONS:
  ok(boolean, description)
  is(got, expected, description)
  isnt(got, expected, description)
  matches(got, regex, description)
  imatches(got, regex, description)
  cmp_ok(got, op, expected, description)

RESULT SET ASSERTIONS:
  results_eq(sql, sql, description)        -- order matters
  set_eq(sql, sql, description)            -- order doesn't matter
  bag_eq(sql, sql, description)            -- duplicates matter
  set_has(sql, sql, description)           -- subset check
  results_ne(sql, sql, description)        -- not equal

EXCEPTION ASSERTIONS:
  throws_ok(sql, errcode, errmsg, description)
  throws_ok(sql, errcode, description)
  throws_ok(sql, errmsg, description)
  lives_ok(sql, description)

PERFORMANCE:
  performs_ok(sql, milliseconds, description)

EXECUTION:
  pg_prove -d dbname -v tests/test_file.sql
  pg_prove -d dbname -v tests/

NAMING CONVENTION:
  File: test_<object_name>.sql
  Description: Plain English behavior sentence
```

---

## Appendix D: TDD Anti-Patterns for Database Development

### D.1 - Anti-Patterns to AVOID

| Anti-Pattern               | Description                                     | Why It's Harmful                                  | Correct Approach                                 |
| -------------------------- | ----------------------------------------------- | ------------------------------------------------- | ------------------------------------------------ |
| **Tests After Code**       | Writing tests after implementation              | Code not designed for testability, lower coverage | Write tests FIRST (RED phase)                    |
| **Test Waterfall**         | Writing all tests before any implementation     | Loses incremental feedback, over-specifies        | One test at a time                               |
| **Ignoring Refactor**      | Skipping the refactor phase                     | Accumulates technical debt despite tests          | Always refactor after GREEN                      |
| **Testing Implementation** | Testing HOW code works, not WHAT it does        | Brittle tests that break on refactoring           | Test behavior and outcomes                       |
| **Silent Failures**        | Tests that pass but don't actually verify       | False confidence, bugs slip through               | Use explicit assertions, verify test fails first |
| **Shared State**           | Tests that depend on other tests' data          | Order-dependent, flaky test suite                 | Each test is self-contained (BEGIN/ROLLBACK)     |
| **Missing NULL Tests**     | Not testing NULL parameter handling             | NULL-related bugs in production                   | Always test NULL inputs                          |
| **Copy-Paste Tests**       | Duplicating test code instead of parameterizing | Maintenance burden, inconsistency                 | Use helper functions, parameterized patterns     |
| **Excessive Mocking**      | Mocking the database in database tests          | Tests don't verify real behavior                  | Use transaction-wrapped real queries             |
| **Ignoring Edge Cases**    | Only testing happy path                         | Boundary bugs in production                       | Test zero, empty, max, boundary values           |

### D.2 - Perseus-Specific Anti-Patterns

| Anti-Pattern                  | Description                                                                  | Impact                                         | Fix                               |
| ----------------------------- | ---------------------------------------------------------------------------- | ---------------------------------------------- | --------------------------------- |
| **Trusting GCP DMS Output**   | Deploying DMS conversion without testing                                     | P0 issues in production (100% occurrence rate) | Always test DMS output with pgTAP |
| **Assuming Twin Symmetry**    | Identical procedures get identical DMS treatment | Divergent bugs in "identical" code             | Test each procedure independently |
| **LOWER() Blindness**         | Not testing for unnecessary LOWER() calls                                    | ~39% performance degradation                   | Include performance assertions    |
| **Missing Transaction Tests** | Not testing transaction boundaries                                           | Data corruption risk                           | Test COMMIT/ROLLBACK behavior     |

---

## Document Control

| Version | Date           | Author                      | Changes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| ------- | -------------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0     | 2026-01-13     | Pierre Ribeiro + Claude     | Initial release                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| 1.1     | 2026-01-14     | Pierre Ribeiro + Claude     | Added Article XVI (Brownfield Compatibility), Article XVII (Quality Gates), Appendix B (SQL Server mapping)                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| **2.0** | **2026-04-14** | **Pierre Ribeiro + Claude** | **MAJOR: Integrated TDD mandate. Added Part II (Articles XV-XVIII: TDD Standards), Part III reorganization (Articles XIX-XXI: Compliance), new 6th quality dimension (Test Coverage, 15% weight), Appendix C (pgTAP Quick Reference), Appendix D (TDD Anti-Patterns). Elevated Preamble to declare TDD as constitutional principle. Added Section 5.7 (TDD for functions/procedures), Section 8.5 (Illegal ROLLBACK), Section 11.4 (LOWER() anti-pattern), Section 14.1 update (temp table P0), Section 1.5 (test naming). Reorganized into four Parts.** |

**This Constitution is effective immediately and applies to all code produced for the Perseus Database Migration project.**

---

*End of Constitution v2.0*
