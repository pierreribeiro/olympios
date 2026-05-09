-- =============================================================================
-- T025: Setup Test Database Schema
-- =============================================================================
-- Purpose: Initialize test database infrastructure for Perseus migration
-- Author: Claude Code
-- Created: 2026-01-25
-- Quality Target: ≥7.0/10.0
--
-- Schemas:
--   - perseus_test: Test execution environment (mirrors perseus schema)
--   - fixtures: Sample data for testing
--
-- Objects Created:
--   - Test helper functions (assert_equals, assert_not_null, etc.)
--   - Test execution tracking table
--   - Sample data generator functions
--   - Test cleanup procedures
--
-- Constitution Compliance:
--   - Article I: snake_case naming, schema-qualified references
--   - Article III: Set-based execution (no cursors)
--   - Article V: Explicit transactions
--   - Article VII: Structured error handling
-- =============================================================================

\timing on

BEGIN;

-- =============================================================================
-- SECTION 1: TEST EXECUTION TRACKING
-- =============================================================================

-- Drop and recreate to ensure idempotency
DROP TABLE IF EXISTS perseus_test.test_execution_log CASCADE;

CREATE TABLE perseus_test.test_execution_log (
    test_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    test_name VARCHAR(200) NOT NULL,
    test_category VARCHAR(50) NOT NULL, -- unit, integration, performance, smoke
    object_type VARCHAR(50), -- procedure, function, view, table
    object_name TEXT,
    executed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    duration_ms INTEGER,
    status VARCHAR(20) NOT NULL CHECK (status IN ('PASS', 'FAIL', 'SKIP', 'ERROR')),
    assertions_passed INTEGER DEFAULT 0,
    assertions_failed INTEGER DEFAULT 0,
    error_message TEXT,
    test_environment VARCHAR(20) DEFAULT 'dev'
);

CREATE INDEX IF NOT EXISTS idx_test_execution_log_executed_at
    ON perseus_test.test_execution_log(executed_at DESC);
CREATE INDEX IF NOT EXISTS idx_test_execution_log_status
    ON perseus_test.test_execution_log(status);
CREATE INDEX IF NOT EXISTS idx_test_execution_log_object
    ON perseus_test.test_execution_log(object_type, object_name);

COMMENT ON TABLE perseus_test.test_execution_log IS
    'Tracks all test executions for auditing and trend analysis';

-- =============================================================================
-- SECTION 2: TEST ASSERTION HELPERS
-- =============================================================================

-- Function: assert_equals (generic value comparison)
CREATE OR REPLACE FUNCTION perseus_test.assert_equals(
    p_actual ANYELEMENT,
    p_expected ANYELEMENT,
    p_message TEXT DEFAULT 'Assertion failed: values not equal'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $BODY$
BEGIN
    IF p_actual IS DISTINCT FROM p_expected THEN
        RAISE EXCEPTION '% (Expected: %, Actual: %)',
            p_message, p_expected, p_actual
            USING HINT = 'Check test data and expected values';
    END IF;

    RETURN TRUE;
END;
$BODY$;

COMMENT ON FUNCTION perseus_test.assert_equals IS
    'Asserts that two values are equal, raises exception if not';

-- Function: assert_not_null
CREATE OR REPLACE FUNCTION perseus_test.assert_not_null(
    p_value ANYELEMENT,
    p_message TEXT DEFAULT 'Assertion failed: value is NULL'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $BODY$
BEGIN
    IF p_value IS NULL THEN
        RAISE EXCEPTION '%', p_message
            USING HINT = 'Expected non-NULL value';
    END IF;

    RETURN TRUE;
END;
$BODY$;

COMMENT ON FUNCTION perseus_test.assert_not_null IS
    'Asserts that a value is not NULL, raises exception if NULL';

-- Function: assert_true
CREATE OR REPLACE FUNCTION perseus_test.assert_true(
    p_condition BOOLEAN,
    p_message TEXT DEFAULT 'Assertion failed: condition is FALSE'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $BODY$
BEGIN
    IF NOT p_condition THEN
        RAISE EXCEPTION '%', p_message
            USING HINT = 'Expected TRUE condition';
    END IF;

    RETURN TRUE;
END;
$BODY$;

COMMENT ON FUNCTION perseus_test.assert_true IS
    'Asserts that a condition is TRUE, raises exception if FALSE';

-- Function: assert_row_count
CREATE OR REPLACE FUNCTION perseus_test.assert_row_count(
    p_table_name TEXT,
    p_expected_count BIGINT,
    p_message TEXT DEFAULT 'Assertion failed: row count mismatch'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $BODY$
DECLARE
    v_actual_count BIGINT;
BEGIN
    EXECUTE format('SELECT COUNT(*) FROM %I', p_table_name)
        INTO v_actual_count;

    IF v_actual_count != p_expected_count THEN
        RAISE EXCEPTION '% (Expected: %, Actual: %)',
            p_message, p_expected_count, v_actual_count
            USING HINT = format('Table: %s', p_table_name);
    END IF;

    RETURN TRUE;
END;
$BODY$;

COMMENT ON FUNCTION perseus_test.assert_row_count IS
    'Asserts that a table has expected row count, raises exception if not';

-- =============================================================================
-- SECTION 3: TEST DATA MANAGEMENT
-- =============================================================================

-- Function: generate_test_uuid
CREATE OR REPLACE FUNCTION perseus_test.generate_test_uuid()
RETURNS UUID
LANGUAGE sql
IMMUTABLE
AS $BODY$
    SELECT gen_random_uuid();
$BODY$;

COMMENT ON FUNCTION perseus_test.generate_test_uuid IS
    'Generates a random UUID for test data';

-- Function: cleanup_test_data
CREATE OR REPLACE PROCEDURE perseus_test.cleanup_test_data(
    p_schema_name VARCHAR(63) DEFAULT 'perseus_test'
)
LANGUAGE plpgsql
AS $BODY$
DECLARE
    v_table_name TEXT;
    v_row_count BIGINT := 0;
BEGIN
    -- Get all tables in test schema
    FOR v_table_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = p_schema_name
          AND table_type = 'BASE TABLE'
          AND table_name != 'test_execution_log' -- Don't clean log table
    LOOP
        EXECUTE format('TRUNCATE TABLE %I.%I CASCADE', p_schema_name, v_table_name);
        GET DIAGNOSTICS v_row_count = ROW_COUNT;

        RAISE NOTICE 'Cleaned table: %.% (% rows)', p_schema_name, v_table_name, v_row_count;
    END LOOP;

    RAISE NOTICE 'Test data cleanup completed for schema: %', p_schema_name;
END;
$BODY$;

COMMENT ON PROCEDURE perseus_test.cleanup_test_data IS
    'Truncates all test tables except test_execution_log';

-- =============================================================================
-- SECTION 4: FIXTURE DATA HELPERS
-- =============================================================================

-- Table: fixtures.sample_materials (example fixture table)
CREATE TABLE IF NOT EXISTS fixtures.sample_materials (
    material_id INTEGER PRIMARY KEY,
    material_name VARCHAR(200) NOT NULL,
    material_type VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) DEFAULT 'test_user'
);

COMMENT ON TABLE fixtures.sample_materials IS
    'Sample material data for testing';

-- Insert sample fixture data
INSERT INTO fixtures.sample_materials (material_id, material_name, material_type)
VALUES
    (1, 'Test Material 1', 'DNA'),
    (2, 'Test Material 2', 'Protein'),
    (3, 'Test Material 3', 'RNA')
ON CONFLICT (material_id) DO NOTHING;

-- Function: load_fixture_data
CREATE OR REPLACE FUNCTION fixtures.load_fixture_data(
    p_fixture_name VARCHAR(100)
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $BODY$
DECLARE
    v_rows_loaded INTEGER := 0;
BEGIN
    CASE p_fixture_name
        WHEN 'sample_materials' THEN
            -- Already loaded above
            SELECT COUNT(*) INTO v_rows_loaded FROM fixtures.sample_materials;

        WHEN 'empty_test' THEN
            -- Empty fixture for testing empty tables
            v_rows_loaded := 0;

        ELSE
            RAISE EXCEPTION 'Unknown fixture: %', p_fixture_name
                USING HINT = 'Available fixtures: sample_materials, empty_test';
    END CASE;

    RETURN v_rows_loaded;
END;
$BODY$;

COMMENT ON FUNCTION fixtures.load_fixture_data IS
    'Loads predefined fixture data sets for testing';

-- =============================================================================
-- SECTION 5: TEST EXECUTION HELPERS
-- =============================================================================

-- Procedure: log_test_result
CREATE OR REPLACE PROCEDURE perseus_test.log_test_result(
    IN p_test_name VARCHAR(200),
    IN p_test_category VARCHAR(50),
    IN p_object_type VARCHAR(50) DEFAULT NULL,
    IN p_object_name TEXT DEFAULT NULL,
    IN p_duration_ms INTEGER DEFAULT NULL,
    IN p_status VARCHAR(20) DEFAULT 'PASS',
    IN p_assertions_passed INTEGER DEFAULT 0,
    IN p_assertions_failed INTEGER DEFAULT 0,
    IN p_error_message TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $BODY$
BEGIN
    INSERT INTO perseus_test.test_execution_log (
        test_name, test_category, object_type, object_name,
        duration_ms, status, assertions_passed, assertions_failed, error_message
    ) VALUES (
        p_test_name, p_test_category, p_object_type, p_object_name,
        p_duration_ms, p_status, p_assertions_passed, p_assertions_failed, p_error_message
    );

    RAISE NOTICE 'Test logged: % - %', p_test_name, p_status;
END;
$BODY$;

COMMENT ON PROCEDURE perseus_test.log_test_result IS
    'Logs test execution results to test_execution_log table';

-- View: v_test_summary (test execution summary)
CREATE OR REPLACE VIEW perseus_test.v_test_summary AS
SELECT
    test_category,
    COUNT(*) AS total_tests,
    SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN status = 'FAIL' THEN 1 ELSE 0 END) AS failed,
    SUM(CASE WHEN status = 'ERROR' THEN 1 ELSE 0 END) AS errors,
    SUM(CASE WHEN status = 'SKIP' THEN 1 ELSE 0 END) AS skipped,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS pass_rate_pct,
    AVG(duration_ms) AS avg_duration_ms,
    MAX(executed_at) AS last_execution
FROM perseus_test.test_execution_log
GROUP BY test_category
ORDER BY test_category;

COMMENT ON VIEW perseus_test.v_test_summary IS
    'Summary of test execution metrics by category';

-- =============================================================================
-- SECTION 6: VALIDATION
-- =============================================================================

-- Verify all objects created
DO $$
DECLARE
    v_table_count INTEGER;
    v_function_count INTEGER;
    v_view_count INTEGER;
BEGIN
    -- Count tables
    SELECT COUNT(*) INTO v_table_count
    FROM information_schema.tables
    WHERE table_schema IN ('perseus_test', 'fixtures')
      AND table_type = 'BASE TABLE';

    -- Count functions/procedures
    SELECT COUNT(*) INTO v_function_count
    FROM information_schema.routines
    WHERE routine_schema IN ('perseus_test', 'fixtures');

    -- Count views
    SELECT COUNT(*) INTO v_view_count
    FROM information_schema.views
    WHERE table_schema = 'perseus_test';

    RAISE NOTICE '';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'TEST DATABASE SETUP COMPLETE';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE 'Tables created:    %', v_table_count;
    RAISE NOTICE 'Functions/Procs:   %', v_function_count;
    RAISE NOTICE 'Views created:     %', v_view_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Schemas configured:';
    RAISE NOTICE '  - perseus_test: Test execution environment';
    RAISE NOTICE '  - fixtures: Sample test data';
    RAISE NOTICE '';
    RAISE NOTICE 'Helper Functions Available:';
    RAISE NOTICE '  - perseus_test.assert_equals()';
    RAISE NOTICE '  - perseus_test.assert_not_null()';
    RAISE NOTICE '  - perseus_test.assert_true()';
    RAISE NOTICE '  - perseus_test.assert_row_count()';
    RAISE NOTICE '  - perseus_test.cleanup_test_data()';
    RAISE NOTICE '  - perseus_test.log_test_result()';
    RAISE NOTICE '  - fixtures.load_fixture_data()';
    RAISE NOTICE '';
    RAISE NOTICE 'Example Usage:';
    RAISE NOTICE '  SELECT perseus_test.assert_equals(1, 1, ''Test passed'');';
    RAISE NOTICE '  CALL perseus_test.cleanup_test_data(''perseus_test'');';
    RAISE NOTICE '  SELECT * FROM perseus_test.v_test_summary;';
    RAISE NOTICE '=================================================================';
END $$;

COMMIT;

-- =============================================================================
-- END OF SCRIPT
-- =============================================================================
