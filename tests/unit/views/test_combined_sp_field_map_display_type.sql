-- ===================================================================
-- UNIT TEST: test_combined_sp_field_map_display_type
-- ===================================================================
-- Purpose: Unit tests for perseus.combined_sp_field_map_display_type
-- Priority: P2
-- Task: T050 (US1 Phase 3 — Validation)
-- Object: perseus.combined_sp_field_map_display_type
-- Type: VIEW (standard)
-- Created: 2026-03-08
-- ===================================================================
--
-- Columns: id, field_map_id, display_type_id, display,
--          display_layout_id, manditory
--
-- Note: 'manditory' is an intentional misspelling preserved from
-- the T-SQL original for application backward compatibility.
--
-- Dependencies: perseus.smurf_property, perseus.smurf, perseus.property,
--               perseus.display_layout (all base tables)
--
-- Structure: UNION of 5 branches generating synthetic display type rows.
--   All branches filter smurf_property WHERE disabled = 0 and use
--   CROSS JOIN to display_layout filtered by specific dl.id values.
--   Prerequisite: display_layout must contain rows for id IN (1, 3, 6, 7).
--
-- NULL check: id is computed as sp.id + offset + dl.id. Both sp.id
-- and dl.id are primary keys; the composite expression is never NULL.
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
          AND table_name   = 'combined_sp_field_map_display_type'
    ) THEN
        INSERT INTO test_results VALUES (
            1,
            'View Existence',
            'FAILED',
            'View perseus.combined_sp_field_map_display_type not found in information_schema.views',
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
      AND table_name   = 'combined_sp_field_map_display_type';

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
            'No columns found in information_schema.columns for perseus.combined_sp_field_map_display_type',
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
    SELECT COUNT(*) INTO v_row_count FROM perseus.combined_sp_field_map_display_type;

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
    PERFORM * FROM perseus.combined_sp_field_map_display_type LIMIT 1000;

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
-- id is computed as sp.id + branch_offset + dl.id across all 5 branches.
-- smurf_property.id and display_layout.id are both primary keys;
-- the computed expression is never NULL for any qualifying row.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_start      TIMESTAMPTZ := clock_timestamp();
    v_null_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_null_count
    FROM perseus.combined_sp_field_map_display_type
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
UNION ALL SELECT 'UNIT TEST RESULTS: combined_sp_field_map_display_type'
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
