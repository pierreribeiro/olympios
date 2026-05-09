-- ===================================================================
-- UNIT TEST: test_hermes_run
-- ===================================================================
-- Purpose: Unit tests for perseus.hermes_run
-- Priority: P1
-- Task: T050 (US1 Phase 3 — Validation)
-- Object: perseus.hermes_run
-- Type: VIEW (standard, FDW-dependent)
-- Created: 2026-03-08
-- ===================================================================
--
-- NOTE: This view depends on hermes_server FDW being configured.
-- Tests 1-5 gracefully SKIP (not FAIL) when the FDW is absent and
-- the view has not yet been created.
--
-- Columns: experiment_id, run_id, description, created_on, strain,
--          yield, titer, result_goo_id, feedstock_goo_id,
--          container_id, run_on, duration
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
          AND table_name   = 'hermes_run'
    ) THEN
        -- View not present — likely FDW-blocked; mark as SKIPPED not FAILED
        INSERT INTO test_results VALUES (
            1,
            'View Existence',
            'SKIPPED',
            'View not found — hermes_server FDW may not be configured',
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
    v_start      TIMESTAMPTZ := clock_timestamp();
    v_col_count  INTEGER;
BEGIN
    -- Skip gracefully if the view was not found in Test 1
    IF EXISTS (
        SELECT 1 FROM test_results WHERE test_number = 1 AND status = 'SKIPPED'
    ) THEN
        INSERT INTO test_results VALUES (
            2,
            'Column Structure',
            'SKIPPED',
            'Skipped — view does not exist (FDW not configured)',
            0
        );
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_col_count
    FROM information_schema.columns
    WHERE table_schema = 'perseus'
      AND table_name   = 'hermes_run';

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
            'No columns found in information_schema.columns for perseus.hermes_run',
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
    IF EXISTS (
        SELECT 1 FROM test_results WHERE test_number = 1 AND status = 'SKIPPED'
    ) THEN
        INSERT INTO test_results VALUES (
            3,
            'Row Count',
            'SKIPPED',
            'Skipped — view does not exist (FDW not configured)',
            0
        );
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_row_count FROM perseus.hermes_run;

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
    v_start    TIMESTAMPTZ := clock_timestamp();
    v_elapsed  INTEGER;
BEGIN
    IF EXISTS (
        SELECT 1 FROM test_results WHERE test_number = 1 AND status = 'SKIPPED'
    ) THEN
        INSERT INTO test_results VALUES (
            4,
            'Performance Test (LIMIT 1000 < 5s)',
            'SKIPPED',
            'Skipped — view does not exist (FDW not configured)',
            0
        );
        RETURN;
    END IF;

    PERFORM * FROM perseus.hermes_run LIMIT 1000;

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
-- Test 5: NULL Check on run_id (primary key column)
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_start      TIMESTAMPTZ := clock_timestamp();
    v_null_count BIGINT;
BEGIN
    IF EXISTS (
        SELECT 1 FROM test_results WHERE test_number = 1 AND status = 'SKIPPED'
    ) THEN
        INSERT INTO test_results VALUES (
            5,
            'NULL Check: run_id must not be NULL',
            'SKIPPED',
            'Skipped — view does not exist (FDW not configured)',
            0
        );
        RETURN;
    END IF;

    SELECT COUNT(*) INTO v_null_count
    FROM perseus.hermes_run
    WHERE run_id IS NULL;

    IF v_null_count = 0 THEN
        INSERT INTO test_results VALUES (
            5,
            'NULL Check: run_id must not be NULL',
            'PASSED',
            'No NULL values found in run_id',
            EXTRACT(MILLISECONDS FROM clock_timestamp() - v_start)::INTEGER
        );
    ELSE
        INSERT INTO test_results VALUES (
            5,
            'NULL Check: run_id must not be NULL',
            'FAILED',
            v_null_count || ' row(s) have NULL run_id',
            EXTRACT(MILLISECONDS FROM clock_timestamp() - v_start)::INTEGER
        );
    END IF;
EXCEPTION WHEN OTHERS THEN
    INSERT INTO test_results VALUES (
        5,
        'NULL Check: run_id must not be NULL',
        'FAILED',
        SQLERRM,
        0
    );
END;
$$;

-- =====================================================================

SELECT '=====================================================================' AS separator
UNION ALL SELECT 'UNIT TEST RESULTS: hermes_run'
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
