-- ===================================================================
-- UNIT TEST: test_vw_processable_logs
-- ===================================================================
-- Purpose: Unit tests for perseus.vw_processable_logs
-- Priority: P2
-- Task: T050 (US1 Phase 3 — Validation)
-- Object: perseus.vw_processable_logs
-- Type: VIEW (standard)
-- Created: 2026-03-08
-- ===================================================================
--
-- Columns: id, class_id, source, created_on, log_text, file_name,
--          robot_log_checksum, started_on, completed_on, loaded_on,
--          loaded, loadable, robot_run_id, robot_log_type_id
--
-- Dependencies: perseus.robot_log, perseus.robot_log_type,
--               perseus.robot_log_error, perseus.robot_log_read,
--               perseus.robot_log_transfer (all base tables)
--
-- Note: This view applies a time-window filter (created_on within
--       the last calendar month). In a fresh DEV environment the
--       row count may legitimately be 0 — this is not a failure.
--       The NULL check on id confirms the SELECT is structurally
--       sound and robot_log.id is always populated for matching rows.
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
          AND table_name   = 'vw_processable_logs'
    ) THEN
        INSERT INTO test_results VALUES (
            1,
            'View Existence',
            'FAILED',
            'View perseus.vw_processable_logs not found in information_schema.views',
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
      AND table_name   = 'vw_processable_logs';

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
            'No columns found in information_schema.columns for perseus.vw_processable_logs',
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
-- Row count may be 0 in DEV (time-window filter: last 1 month).
-- Always PASS — record count for diagnostic visibility.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_start     TIMESTAMPTZ := clock_timestamp();
    v_row_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_row_count FROM perseus.vw_processable_logs;

    INSERT INTO test_results VALUES (
        3,
        'Row Count',
        'PASSED',
        'Row count: ' || v_row_count || ' (0 is valid — time-window filter active)',
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
    PERFORM * FROM perseus.vw_processable_logs LIMIT 1000;

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
-- Test 5: NULL Check — id must not be NULL for any returned row
-- robot_log.id is the primary key of the base table. Any row that
-- passes the WHERE predicate will have a non-NULL id by definition.
-- A NULL here would indicate a schema or join regression.
-- ---------------------------------------------------------------------
DO $$
DECLARE
    v_start      TIMESTAMPTZ := clock_timestamp();
    v_null_count BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_null_count
    FROM perseus.vw_processable_logs
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
UNION ALL SELECT 'UNIT TEST RESULTS: vw_processable_logs'
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
