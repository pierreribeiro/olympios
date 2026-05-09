-- ============================================================================
-- Object: [object_name]
-- Type: [VIEW | FUNCTION | TABLE | INDEX | CONSTRAINT | PROCEDURE]
-- Priority: [P0 | P1 | P2 | P3]
-- Description: [Brief description of what this object does]
-- ============================================================================
-- Migration Info:
--   Original: source/original/sqlserver/[filename].sql
--   AWS SCT: source/original/pgsql-aws-sct-converted/[filename].sql
--   Quality Score: [score]/10
--   Analyst: [name]
--   Date: [YYYY-MM-DD]
-- ============================================================================
-- Dependencies:
--   Tables: [schema.table1, schema.table2, ...]
--   Views: [schema.view1, schema.view2, ...]
--   Functions: [schema.function1, schema.function2, ...]
--   FDW: [hermes_fdw, sqlapps_fdw, deimeter_fdw] (if applicable)
-- ============================================================================
-- Constitution Compliance:
--   [✓] I. ANSI-SQL Primacy - Uses standard SQL constructs
--   [✓] II. Strict Typing - All casts explicit (CAST or ::)
--   [✓] III. Set-Based - No cursors, no WHILE loops
--   [✓] IV. Atomic Transactions - Explicit BEGIN/COMMIT/ROLLBACK
--   [✓] V. Naming & Scoping - snake_case, schema-qualified
--   [✓] VI. Error Resilience - Specific exceptions, meaningful errors
--   [✓] VII. Modular Logic - Single responsibility, clean separation
-- ============================================================================
-- Performance Notes:
--   Baseline (SQL Server): [X ms @ Y rows]
--   Expected (PostgreSQL): [X ms @ Y rows] (±20% acceptable)
--   Indexes required: [List critical indexes for query plans]
-- ============================================================================
-- Change Log:
--   [YYYY-MM-DD] [Author] - Initial migration from SQL Server
--   [YYYY-MM-DD] [Author] - [Description of changes]
-- ============================================================================

-- ============================================================================
-- EXAMPLE 1: VIEW Template
-- ============================================================================

-- DROP VIEW IF EXISTS perseus.[view_name] CASCADE;

CREATE OR REPLACE VIEW perseus.[view_name] AS
SELECT
    t1.column1::INTEGER AS column1,
    t1.column2::VARCHAR(100) AS column2,
    t2.column3::TIMESTAMP AS column3,
    COALESCE(t1.nullable_column, 'default_value') AS nullable_column
FROM
    perseus.table1 t1
    INNER JOIN perseus.table2 t2 ON t1.id = t2.foreign_id
WHERE
    t1.is_active = TRUE
    AND t2.created_at >= CURRENT_TIMESTAMP - INTERVAL '30 days';

-- Constitution V: Schema-qualified references (perseus.table1, not just table1)
-- Constitution II: Explicit casts (::INTEGER, not implicit conversion)

COMMENT ON VIEW perseus.[view_name] IS
'[Brief description of view purpose and usage]
Updated: [YYYY-MM-DD] | Owner: [team/person]';

-- ============================================================================
-- EXAMPLE 2: MATERIALIZED VIEW Template (for SQL Server Indexed Views)
-- ============================================================================

-- DROP MATERIALIZED VIEW IF EXISTS perseus.[materialized_view_name] CASCADE;

CREATE MATERIALIZED VIEW perseus.[materialized_view_name] AS
SELECT
    mt.material_id,
    mt.transition_id,
    tm.goo_id,
    mt.created_at::TIMESTAMP AS created_at
FROM
    perseus.material_transition mt
    INNER JOIN perseus.transition_material tm
        ON mt.transition_id = tm.transition_id
        AND mt.material_id = tm.material_id
WITH DATA;

-- CRITICAL: UNIQUE index required for REFRESH CONCURRENTLY (no query blocking)
CREATE UNIQUE INDEX CONCURRENTLY idx_[materialized_view_name]_unique
    ON perseus.[materialized_view_name] (material_id, transition_id);

-- Additional indexes for query performance
CREATE INDEX CONCURRENTLY idx_[materialized_view_name]_goo_id
    ON perseus.[materialized_view_name] (goo_id);

COMMENT ON MATERIALIZED VIEW perseus.[materialized_view_name] IS
'Materialized view for [purpose]. Refreshed every [interval] via pg_cron.
Refresh command: REFRESH MATERIALIZED VIEW CONCURRENTLY perseus.[materialized_view_name];
Updated: [YYYY-MM-DD] | Owner: [team/person]';

-- ============================================================================
-- EXAMPLE 3: FUNCTION Template (Table-Valued)
-- ============================================================================

-- DROP FUNCTION IF EXISTS perseus.[function_name](parameter_type) CASCADE;

CREATE OR REPLACE FUNCTION perseus.[function_name](
    p_parameter1 INTEGER,
    p_parameter2 VARCHAR(100) DEFAULT NULL
)
RETURNS TABLE (
    output_column1 INTEGER,
    output_column2 VARCHAR(100),
    output_column3 TIMESTAMP
)
LANGUAGE plpgsql
STABLE -- IMMUTABLE | STABLE | VOLATILE (choose based on function behavior)
SECURITY DEFINER -- or SECURITY INVOKER
AS $$
DECLARE
    v_local_variable INTEGER;
BEGIN
    -- Constitution IV: Explicit transaction management
    -- Constitution VI: Specific exception handling

    -- Validate input parameters
    IF p_parameter1 IS NULL THEN
        RAISE EXCEPTION 'Parameter p_parameter1 cannot be NULL'
            USING HINT = 'Provide a valid integer value',
                  ERRCODE = '22004'; -- null_value_not_allowed
    END IF;

    -- Business logic using set-based operations (Constitution III)
    RETURN QUERY
    SELECT
        t.id::INTEGER,
        t.name::VARCHAR(100),
        t.created_at::TIMESTAMP
    FROM
        perseus.some_table t
    WHERE
        t.some_column = p_parameter1
        AND (p_parameter2 IS NULL OR t.another_column = p_parameter2)
    ORDER BY
        t.created_at DESC;

    -- Constitution VI: Specific exception types
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Foreign key constraint violated in [function_name]: %', SQLERRM
            USING HINT = 'Ensure referenced record exists',
                  ERRCODE = '23503';
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Unique constraint violated in [function_name]: %', SQLERRM
            USING HINT = 'Duplicate value detected',
                  ERRCODE = '23505';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Unexpected error in [function_name]: % (SQLSTATE: %)', SQLERRM, SQLSTATE
            USING HINT = 'Contact DBA team for investigation';
END;
$$;

-- Constitution V: Named parameters (p_prefix), schema-qualified calls
COMMENT ON FUNCTION perseus.[function_name](INTEGER, VARCHAR) IS
'[Brief description of function purpose and usage]
Parameters:
  - p_parameter1: [Description]
  - p_parameter2: [Description] (optional, default NULL)
Returns: Table of [description]
Updated: [YYYY-MM-DD] | Owner: [team/person]';

-- ============================================================================
-- EXAMPLE 4: FUNCTION Template (Scalar)
-- ============================================================================

CREATE OR REPLACE FUNCTION perseus.[scalar_function_name](
    p_input INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
IMMUTABLE -- Use IMMUTABLE if result depends ONLY on input parameters
STRICT -- Returns NULL if any parameter is NULL
AS $$
BEGIN
    RETURN p_input * 2;
END;
$$;

-- ============================================================================
-- EXAMPLE 5: TABLE Template
-- ============================================================================

-- DROP TABLE IF EXISTS perseus.[table_name] CASCADE;

CREATE TABLE perseus.[table_name] (
    -- Primary key with IDENTITY (Constitution: GENERATED ALWAYS, not SERIAL)
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Foreign keys with explicit type casting
    parent_id INTEGER,
    related_entity_id INTEGER NOT NULL,

    -- Data columns with explicit types
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',

    -- Numeric with explicit precision
    amount NUMERIC(19,4), -- For MONEY conversions

    -- Timestamps (use TIMESTAMP, not DATETIME)
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP, -- Soft delete pattern

    -- Boolean (not BIT)
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- UUID for UNIQUEIDENTIFIER
    external_id UUID,

    -- Check constraints (inline)
    CONSTRAINT chk_[table_name]_status
        CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),

    -- Unique constraints
    CONSTRAINT uq_[table_name]_external_id
        UNIQUE (external_id)
);

-- Foreign key constraints (separate for clarity)
ALTER TABLE perseus.[table_name]
    ADD CONSTRAINT fk_[table_name]_parent
        FOREIGN KEY (parent_id)
        REFERENCES perseus.[parent_table](id)
        ON DELETE CASCADE
        ON UPDATE CASCADE;

ALTER TABLE perseus.[table_name]
    ADD CONSTRAINT fk_[table_name]_related_entity
        FOREIGN KEY (related_entity_id)
        REFERENCES perseus.[related_table](id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE;

-- Indexes for query performance
CREATE INDEX idx_[table_name]_parent_id
    ON perseus.[table_name](parent_id)
    WHERE deleted_at IS NULL; -- Partial index for active records

CREATE INDEX idx_[table_name]_status_created
    ON perseus.[table_name](status, created_at DESC)
    WHERE is_active = TRUE;

-- Table comments
COMMENT ON TABLE perseus.[table_name] IS
'[Brief description of table purpose and entity]
Updated: [YYYY-MM-DD] | Owner: [team/person]';

COMMENT ON COLUMN perseus.[table_name].status IS
'Allowed values: pending, active, completed, cancelled';

-- ============================================================================
-- EXAMPLE 6: TEMPORARY TABLE Pattern (for GooList UDT replacement)
-- ============================================================================

CREATE TEMPORARY TABLE tmp_goo_list (
    goo_id INTEGER PRIMARY KEY
) ON COMMIT DROP; -- Auto-cleanup after transaction

-- Usage in function
CREATE OR REPLACE FUNCTION perseus.mcgetupstreambylist()
RETURNS TABLE (
    goo_id INTEGER,
    parent_goo_id INTEGER,
    depth INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Caller populates tmp_goo_list before calling this function
    RETURN QUERY
    SELECT
        mt.from_goo_id::INTEGER,
        mt.to_goo_id::INTEGER,
        1::INTEGER AS depth
    FROM
        tmp_goo_list tgl
        INNER JOIN perseus.material_transition mt ON tgl.goo_id = mt.from_goo_id;
END;
$$;

-- ============================================================================
-- EXAMPLE 7: STORED PROCEDURE Template
-- ============================================================================

CREATE OR REPLACE PROCEDURE perseus.[procedure_name](
    p_input_param INTEGER,
    p_output_param OUT INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_local_var INTEGER;
BEGIN
    -- Constitution IV: Explicit transaction
    -- NOTE: Caller manages transaction (BEGIN/COMMIT/ROLLBACK)

    -- Business logic
    SELECT COUNT(*)::INTEGER
    INTO v_local_var
    FROM perseus.some_table
    WHERE some_column = p_input_param;

    p_output_param := v_local_var;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error in [procedure_name]: %', SQLERRM;
END;
$$;

-- ============================================================================
-- GRANT STATEMENTS (if applicable)
-- ============================================================================

-- Read-only access
GRANT SELECT ON perseus.[object_name] TO perseus_readonly;

-- Read-write access
GRANT SELECT, INSERT, UPDATE, DELETE ON perseus.[object_name] TO perseus_readwrite;

-- Execute permission for functions
GRANT EXECUTE ON FUNCTION perseus.[function_name](INTEGER, VARCHAR) TO perseus_readwrite;

-- ============================================================================
-- VALIDATION QUERIES
-- ============================================================================

-- Test query for views
-- SELECT * FROM perseus.[view_name] LIMIT 10;

-- Test query for functions
-- SELECT * FROM perseus.[function_name](123, 'test_value');

-- Test query for tables
-- SELECT COUNT(*) FROM perseus.[table_name];

-- ============================================================================
-- ROLLBACK SCRIPT (for deployment safety)
-- ============================================================================

-- To rollback this migration:
-- DROP [VIEW | MATERIALIZED VIEW | FUNCTION | TABLE] IF EXISTS perseus.[object_name] CASCADE;

-- ============================================================================
-- END OF TEMPLATE
-- ============================================================================
