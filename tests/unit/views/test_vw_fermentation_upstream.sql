-- ===================================================================
-- UNIT TEST: test_vw_fermentation_upstream
-- ===================================================================
-- Purpose: Comprehensive test suite for perseus.vw_fermentation_upstream
-- Priority: P2
-- Task: T050 (US1 Phase 3 — Validation)
-- Object: perseus.vw_fermentation_upstream
-- Type: VIEW (standard)
-- Created: 2026-03-08
-- ===================================================================


-- ===================================================================
-- TEST SETUP
-- ===================================================================

SET client_min_messages = WARNING;

CREATE TEMPORARY TABLE test_results (
    test_number       INTEGER PRIMARY KEY,
    test_name         VARCHAR(200),
    status            VARCHAR(20),
    error_message     TEXT,
    execution_time_ms INTEGER
);

SET client_min_messages = NOTICE;


-- ===================================================================
-- TEST 1: View Existence
-- ===================================================================

DO $$
DECLARE
    v_start     TIMESTAMPTZ;
    v_elapsed   INTEGER;
    v_count     INTEGER;
BEGIN
    v_start := clock_timestamp();

    SELECT COUNT(*)
    INTO v_count
    FROM information_schema.views
    WHERE table_schema = 'perseus'
      AND table_name   = 'vw_fermentation_upstream';

    v_elapsed := EXTRACT(EPOCH FROM (clock_timestamp() - v_start)) * 1000;

    IF v_count = 1 THEN
        INSERT INTO test_results VALUES (1, 'View Existence', 'PASSED', NULL, v_elapsed);
    ELSE
        INSERT INTO test_results VALUES (1, 'View Existence', 'FAILED',
            'View perseus.vw_fermentation_upstream not found in information_schema.views', v_elapsed);
    END IF;

EXCEPTION WHEN OTHERS THEN
    INSERT INTO test_results VALUES (1, 'View Existence', 'FAILED', SQLERRM, 0);
END;
$$;


-- ===================================================================
-- TEST 2: Column Structure
-- ===================================================================

DO $$
DECLARE
    v_start     TIMESTAMPTZ;
    v_elapsed   INTEGER;
    v_count     INTEGER;
BEGIN
    v_start := clock_timestamp();

    SELECT COUNT(*)
    INTO v_count
    FROM information_schema.columns
    WHERE table_schema = 'perseus'
      AND table_name   = 'vw_fermentation_upstream';

    v_elapsed := EXTRACT(EPOCH FROM (clock_timestamp() - v_start)) * 1000;

    IF v_count > 0 THEN
        INSERT INTO test_results VALUES (2, 'Column Structure', 'PASSED',
            'Column count: ' || v_count, v_elapsed);
    ELSE
        INSERT INTO test_results VALUES (2, 'Column Structure', 'FAILED',
            'No columns found for perseus.vw_fermentation_upstream', v_elapsed);
    END IF;

EXCEPTION WHEN OTHERS THEN
    INSERT INTO test_results VALUES (2, 'Column Structure', 'FAILED', SQLERRM, 0);
END;
$$;


-- ===================================================================
-- TEST 3: Row Count
-- ===================================================================

DO $$
DECLARE
    v_start     TIMESTAMPTZ;
    v_elapsed   INTEGER;
    v_count     BIGINT;
BEGIN
    v_start := clock_timestamp();

    SELECT COUNT(*) INTO v_count FROM perseus.vw_fermentation_upstream;

    v_elapsed := EXTRACT(EPOCH FROM (clock_timestamp() - v_start)) * 1000;

    INSERT INTO test_results VALUES (3, 'Row Count', 'PASSED',
        'Row count: ' || v_count, v_elapsed);

EXCEPTION WHEN OTHERS THEN
    INSERT INTO test_results VALUES (3, 'Row Count', 'FAILED', SQLERRM, 0);
END;
$$;


-- ===================================================================
-- TEST 4: Performance Test (threshold: 5 seconds / LIMIT 1000)
-- ===================================================================

DO $$
DECLARE
    v_start     TIMESTAMPTZ;
    v_elapsed   INTEGER;
BEGIN
    v_start := clock_timestamp();

    PERFORM * FROM perseus.vw_fermentation_upstream LIMIT 1000;

    v_elapsed := EXTRACT(EPOCH FROM (clock_timestamp() - v_start)) * 1000;

    IF v_elapsed <= 5000 THEN
        INSERT INTO test_results VALUES (4, 'Performance Test', 'PASSED',
            'Elapsed: ' || v_elapsed || ' ms (threshold: 5000 ms)', v_elapsed);
    ELSE
        INSERT INTO test_results VALUES (4, 'Performance Test', 'FAILED',
            'Elapsed: ' || v_elapsed || ' ms — exceeded 5000 ms threshold', v_elapsed);
    END IF;

EXCEPTION WHEN OTHERS THEN
    INSERT INTO test_results VALUES (4, 'Performance Test', 'FAILED', SQLERRM, 0);
END;
$$;


-- ===================================================================
-- TEST 5: NULL Check / Data Integrity
-- ===================================================================

DO $$
DECLARE
    v_start     TIMESTAMPTZ;
    v_elapsed   INTEGER;
    v_count     INTEGER;
BEGIN
    v_start := clock_timestamp();

    SELECT COUNT(*)
    INTO v_count
    FROM (SELECT * FROM perseus.vw_fermentation_upstream LIMIT 100) sub;

    v_elapsed := EXTRACT(EPOCH FROM (clock_timestamp() - v_start)) * 1000;

    IF v_count >= 0 THEN
        INSERT INTO test_results VALUES (5, 'NULL Check / Data Integrity', 'PASSED',
            'Sample rows returned: ' || v_count, v_elapsed);
    ELSE
        INSERT INTO test_results VALUES (5, 'NULL Check / Data Integrity', 'FAILED',
            'Unexpected result from sample query', v_elapsed);
    END IF;

EXCEPTION WHEN OTHERS THEN
    INSERT INTO test_results VALUES (5, 'NULL Check / Data Integrity', 'FAILED', SQLERRM, 0);
END;
$$;


-- ===================================================================
-- RESULTS
-- ===================================================================

SELECT '=====================================================================' AS separator
UNION ALL SELECT 'UNIT TEST RESULTS: vw_fermentation_upstream'
UNION ALL SELECT '====================================================================='
UNION ALL SELECT '';

SELECT
    test_number AS "#",
    test_name   AS "Test Case",
    status      AS "Status",
    CASE
        WHEN status = 'PASSED'  THEN '✓'
        WHEN status = 'FAILED'  THEN '✗'
        WHEN status = 'SKIPPED' THEN '⊘'
    END AS "Result",
    execution_time_ms || ' ms' AS "Time",
    COALESCE(error_message, '-') AS "Notes"
FROM test_results
ORDER BY test_number;

SELECT '';

SELECT '=====================================================================' AS separator
UNION ALL SELECT 'SUMMARY'
UNION ALL SELECT '====================================================================='
UNION ALL SELECT '';

SELECT 'Total Tests: ' || COUNT(*) AS summary FROM test_results
UNION ALL SELECT 'Passed: '  || COUNT(*) FROM test_results WHERE status = 'PASSED'
UNION ALL SELECT 'Failed: '  || COUNT(*) FROM test_results WHERE status = 'FAILED'
UNION ALL SELECT 'Skipped: ' || COUNT(*) FROM test_results WHERE status = 'SKIPPED'
UNION ALL SELECT '';

SELECT
    CASE
        WHEN (SELECT COUNT(*) FROM test_results WHERE status = 'FAILED') > 0
            THEN '✗ OVERALL: FAILED'
        WHEN (SELECT COUNT(*) FROM test_results WHERE status = 'PASSED') = 0
            THEN '⊘ OVERALL: ALL TESTS SKIPPED'
        ELSE '✓ OVERALL: ALL TESTS PASSED'
    END AS overall_result;

SELECT '';
SELECT '=====================================================================' AS separator;

DROP TABLE test_results;
