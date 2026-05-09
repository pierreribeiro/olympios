-- ===================================================================
-- UNIT TEST: test_combined_sp_field_map
-- ===================================================================
-- Purpose: Unit tests for perseus.combined_sp_field_map
-- Priority: P2
-- Task: T050 (US1 Phase 3 — Validation)
-- Object: perseus.combined_sp_field_map
-- Type: VIEW (standard)
-- Created: 2026-03-08
-- ===================================================================
--
-- Columns: id, field_map_block_id, name, description, display_order,
--          setter, lookup, lookup_service, nullable, field_map_type_id,
--          database_id, save_sequence, onchange, field_map_set_id
--
-- Dependencies: perseus.smurf_property, perseus.smurf, perseus.property,
--               perseus.unit, perseus.property_option (all base tables)
--
-- Structure: UNION of 3 branches generating synthetic field_map records
--   Branch 1: id = sp.id + 20000  (reading edit, save_seq=1, with setter)
--   Branch 2: id = sp.id + 30000  (list/CSV, save_seq=2, no setter)
--   Branch 3: id = sp.id + 40000  (single reading edit, save_seq=2, with setter)
--
-- NULL check: id is a computed expression (sp.id + offset) and is always
-- non-NULL. Validates the UNION across all three branches executes cleanly.
-- ===================================================================

SET client_min_messages = WARNING;
CREATE TEMPORARY TABLE test_results (
    test_number      INTEGER PRIMARY KEY,
    test_name        VARCHAR(200),
    status           VARCHAR(20),
    error_message    TEXT,
    execution_time_ms INTEGER
);
SET client_min_messages = NOTICE;

-- ---------------------------------------------------------------------
-- Test 1: View Existence
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_start TIMESTAMPTZ := clock_timestamp();
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.views
        WHERE table_schema = 'perseus'
          AND table_name   = 'combined_sp_field_map'
    ) THEN
        INSERT INTO test_results VALUES (
            1,
            'View Existence',
            'FAILED',
            'View perseus.combined_sp_field_map not found in information_schema.views',
            0
        );
        RETURN;
    END IF;

    INSERT INTO test_results VALUES (
        1,
        'View Existence',
        'PASSED',
        NULL,
        EXTRACT(MILLISECONDS FROM clock_timestamp() - v_start)::INTEGER
    );
EXCEPTION WHEN OTHERS THEN
    INSERT INTO test_results VALUES (
        1,
        'View Existence',
        'FAILED',
        SQLERRM,
        0
    );
END;
$$;

-- ---------------------------------------------------------------------
-- Test 2: Column Structure
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_start     TIMESTAMPTZ := clock_timestamp();
    v_col_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_col_count
    FROM information_schema.columns
    WHERE table_schema = 'perseus'
      AND table_name   = 'combined_sp_field_map';

    IF v_col_count > 0 THEN
        INSERT INTO test_results VALUES (
            2,
            'Column Structure',
            'PASSED',
            'Column count: ' || v_col_count,
            EXTRACT(MILLISECONDS FROM clock_timestamp() - v_start)::INTEGER
        );
    ELSE
        INSERT INTO test_results VALUES (
            2,
            'Column Structure',
            'FAILED',
            'No columns found in information_schema.columns for perseus.combined_sp_field_map',
            EXTRACT(MILLISECONDS FROM clock_timestamp() - v_start)::INTEGER
        );
    END IF;
EXCEPTION WHEN OTHERS THEN
    INSERT INTO test_results VALUES (
        2,
        'Column Structure',
        'FAILED',
        SQLERRM,
        0
    );
END;
$$;

-- ---------------------------------------------------------------------
-- Test 3: Row Count
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_start     TIMESTAMPTZ := clock_timestamp();
    v_row_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_row_count FROM perseus.combined_sp_field_map;

    INSERT INTO test_results VALUES (
        3,
        'Row Count',
        'PASSED',
        'Row count: ' || v_row_count,
        EXTRACT(MILLISECONDS FROM clock_timestamp() - v_start)::INTEGER
    );
EXCEPTION WHEN OTHERS THEN
    INSERT INTO test_results VALUES (
        3,
        'Row Count',
        'FAILED',
        SQLERRM,
        0
    );
END;
$$;

-- ---------------------------------------------------------------------
-- Test 4: Performance Test (LIMIT 1000, threshold 5 seconds)
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_start   TIMESTAMPTZ := clock_timestamp();
    v_elapsed INTEGER;
BEGIN
    PERFORM * FROM perseus.combined_sp_field_map LIMIT 1000;

    v_elapsed := EXTRACT(MILLISECONDS FROM clock_timestamp() - v_start)::INTEGER;

    IF v_elapsed < 5000 THEN
        INSERT INTO test_results VALUES (
            4,
            'Performance Test (LIMIT 1000 < 5s)',
            'PASSED',
            'Elapsed: ' || v_elapsed || ' ms (threshold: 5000 ms)',
            v_elapsed
        );
    ELSE
        INSERT INTO test_results VALUES (
            4,
            'Performance Test (LIMIT 1000 < 5s)',
            'FAILED',
            'Elapsed ' || v_elapsed || ' ms exceeds 5000 ms threshold',
            v_elapsed
        );
    END IF;
EXCEPTION WHEN OTHERS THEN
    INSERT INTO test_results VALUES (
        4,
        'Performance Test (LIMIT 1000 < 5s)',
        'FAILED',
        SQLERRM,
        0
    );
END;
$$;

-- ---------------------------------------------------------------------
-- Test 5: NULL Check — id must not be NULL
-- id is computed as sp.id + an integer offset (20000, 30000, 40000).
-- smurf_property.id is a primary key and is never NULL, so the
-- computed id must also be non-NULL across all three UNION branches.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_start      TIMESTAMPTZ := clock_timestamp();
    v_null_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_null_count
    FROM perseus.combined_sp_field_map
    WHERE id IS NULL;

    IF v_null_count = 0 THEN
        INSERT INTO test_results VALUES (
            5,
            'NULL Check: id must not be NULL',
            'PASSED',
            'No NULL values found in id',
            EXTRACT(MILLISECONDS FROM clock_timestamp() - v_start)::INTEGER
        );
    ELSE
        INSERT INTO test_results VALUES (
            5,
            'NULL Check: id must not be NULL',
            'FAILED',
            v_null_count || ' row(s) have NULL id',
            EXTRACT(MILLISECONDS FROM clock_timestamp() - v_start)::INTEGER
        );
    END IF;
EXCEPTION WHEN OTHERS THEN
    INSERT INTO test_results VALUES (
        5,
        'NULL Check: id must not be NULL',
        'FAILED',
        SQLERRM,
        0
    );
END;
$$;

-- =====================================================================

SELECT '=====================================================================' AS separator
UNION ALL SELECT 'UNIT TEST RESULTS: combined_sp_field_map'
UNION ALL SELECT '====================================================================='
UNION ALL SELECT '';

SELECT test_number AS "#",
       test_name   AS "Test Case",
       status      AS "Status",
       CASE WHEN status = 'PASSED'  THEN '✓'
            WHEN status = 'FAILED'  THEN '✗'
            WHEN status = 'SKIPPED' THEN '⊘'
       END         AS "Result",
       execution_time_ms || ' ms' AS "Time",
       COALESCE(error_message, '-') AS "Notes"
FROM test_results
ORDER BY test_number;

SELECT '';
SELECT '=====================================================================' AS separator
UNION ALL SELECT 'SUMMARY'
UNION ALL SELECT '====================================================================='
UNION ALL SELECT '';
SELECT 'Total Tests: '   || COUNT(*)                                     AS summary FROM test_results
UNION ALL SELECT 'Passed: '  || COUNT(*) FROM test_results WHERE status = 'PASSED'
UNION ALL SELECT 'Failed: '  || COUNT(*) FROM test_results WHERE status = 'FAILED'
UNION ALL SELECT 'Skipped: ' || COUNT(*) FROM test_results WHERE status = 'SKIPPED'
UNION ALL SELECT '';
SELECT CASE
    WHEN (SELECT COUNT(*) FROM test_results WHERE status = 'FAILED')  > 0 THEN '✗ OVERALL: FAILED'
    WHEN (SELECT COUNT(*) FROM test_results WHERE status = 'PASSED') = 0 THEN '⊘ OVERALL: ALL TESTS SKIPPED'
    ELSE '✓ OVERALL: ALL TESTS PASSED'
END AS overall_result;
SELECT '';
SELECT '=====================================================================' AS separator;
DROP TABLE test_results;
