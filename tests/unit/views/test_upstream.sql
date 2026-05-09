-- ===================================================================
-- UNIT TEST: test_upstream
-- ===================================================================
-- Purpose: Test suite for perseus.upstream (recursive CTE view)
-- Priority: P1
-- Task: T048 (US1 Phase 3 — Validation)
-- Object: perseus.upstream
-- Type: VIEW (recursive CTE with CYCLE detection)
-- Created: 2026-03-08
-- ===================================================================
--
-- Test Coverage:
--   1. View Existence              — information_schema.views lookup
--   2. Column Structure            — 4 expected columns present
--   3. Row Count (sampled)         — LIMIT 100 sample, always PASS
--   4. Performance Test            — LIMIT 1000 within 10 second threshold
--   5. No NULL start_point         — sampled 500 rows
--   6. Level is Positive           — all levels >= 1 (sampled 500 rows)
--   7. Path Format Validation      — all paths start with '/' (sampled 500 rows)
--
-- Dependencies:
--   - perseus.translated (materialized view — must exist before this view)
--   - perseus.upstream   (view under test)
--
-- Notes:
--   - Tests 3, 5, 6, 7 use sampled row counts to avoid full-graph scan cost.
--   - The view projects: start_point, end_point, path, level.
--     (The internal CTE alias 'child' is exposed as 'end_point' in the final
--      SELECT; column structure test validates all four projected names.)
--   - CYCLE clause (PostgreSQL 14+) provides cycle safety — not tested here
--     because it requires cyclic data. Verified by code review in upstream.sql.
-- ===================================================================


-- ===================================================================
-- TEST SETUP
-- ===================================================================

-- Suppress NOTICE output during temp table creation
SET client_min_messages = WARNING;

CREATE TEMPORARY TABLE test_results (
    test_number      INTEGER      PRIMARY KEY,
    test_name        VARCHAR(200) NOT NULL,
    status           VARCHAR(20)  NOT NULL,
    error_message    TEXT,
    execution_time_ms INTEGER
);

-- Restore NOTICE so test progress is visible
SET client_min_messages = NOTICE;


-- ===================================================================
-- TEST CASE 1: View Existence
-- ===================================================================
-- Confirms perseus.upstream is registered in information_schema.views.
-- A missing row here means the CREATE OR REPLACE VIEW failed silently
-- or was never executed — all downstream tests would be meaningless.
-- ===================================================================
DO $$
DECLARE
    v_start_time      TIMESTAMP;
    v_end_time        TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_test_passed     BOOLEAN := FALSE;
    v_error_message   TEXT;
BEGIN
    v_start_time := clock_timestamp();

    IF EXISTS (
        SELECT 1
        FROM information_schema.views
        WHERE table_schema = 'perseus'
          AND table_name   = 'upstream'
    ) THEN
        v_test_passed   := TRUE;
        v_error_message := NULL;
    ELSE
        v_test_passed   := FALSE;
        v_error_message := 'View perseus.upstream not found in information_schema.views';
    END IF;

    v_end_time          := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        1,
        'View Existence',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message,
        v_execution_time_ms
    );

    RAISE NOTICE 'Test 1 — View Existence: %',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED — ' || v_error_message END;
END $$;


-- ===================================================================
-- TEST CASE 2: Column Structure Validation
-- ===================================================================
-- Verifies the four expected columns are present in the view:
--   start_point, end_point, path, level
-- Count = 4 confirms no columns were dropped or renamed.
-- ===================================================================
DO $$
DECLARE
    v_start_time      TIMESTAMP;
    v_end_time        TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_column_count    INTEGER;
    v_test_passed     BOOLEAN := FALSE;
    v_error_message   TEXT;
BEGIN
    v_start_time := clock_timestamp();

    SELECT COUNT(*)::INTEGER
    INTO v_column_count
    FROM information_schema.columns
    WHERE table_schema = 'perseus'
      AND table_name   = 'upstream'
      AND column_name  IN ('start_point', 'end_point', 'path', 'level');

    v_test_passed := (v_column_count = 4);

    IF NOT v_test_passed THEN
        v_error_message :=
            'Expected 4 columns (start_point, end_point, path, level), found ' ||
            v_column_count::TEXT;
    END IF;

    v_end_time          := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        2,
        'Column Structure Validation',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        COALESCE(v_error_message, 'All 4 columns present: start_point, end_point, path, level'),
        v_execution_time_ms
    );

    RAISE NOTICE 'Test 2 — Column Structure: % (% of 4 expected columns found)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_column_count;
END $$;


-- ===================================================================
-- TEST CASE 3: Row Count Validation (sampled)
-- ===================================================================
-- Counts rows from a LIMIT 100 sample. This test always PASSES —
-- the purpose is to record a baseline count for regression tracking.
-- A full COUNT(*) is intentionally avoided: the view is a full-graph
-- recursive expansion and may produce millions of rows on production
-- data, making an unsampled count prohibitively slow.
-- ===================================================================
DO $$
DECLARE
    v_start_time      TIMESTAMP;
    v_end_time        TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_row_count       BIGINT;
BEGIN
    v_start_time := clock_timestamp();

    SELECT COUNT(*)
    INTO v_row_count
    FROM (
        SELECT *
        FROM perseus.upstream
        LIMIT 100
    ) AS sub;

    v_end_time          := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        3,
        'Row Count Validation (sampled, LIMIT 100)',
        'PASSED',
        'Sample row count: ' || v_row_count::TEXT,
        v_execution_time_ms
    );

    RAISE NOTICE 'Test 3 — Row Count (sampled): PASSED — % rows in LIMIT 100 sample',
        v_row_count;
END $$;


-- ===================================================================
-- TEST CASE 4: Performance Test
-- ===================================================================
-- Executes LIMIT 1000 against the view and asserts completion within
-- 10 seconds. The threshold is conservative relative to expected
-- production graph size but guards against catastrophic plan regressions
-- (e.g., nested-loop without index, missing CYCLE guard causing runaway).
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time    INTERVAL;
    v_threshold         INTERVAL := INTERVAL '10 seconds';
    v_test_passed       BOOLEAN  := FALSE;
    v_execution_time_ms INTEGER;
BEGIN
    v_start_time := clock_timestamp();

    PERFORM *
    FROM perseus.upstream
    LIMIT 1000;

    v_end_time          := clock_timestamp();
    v_execution_time    := v_end_time - v_start_time;
    v_execution_time_ms := EXTRACT(EPOCH FROM v_execution_time)::INTEGER * 1000
                           + EXTRACT(MILLISECONDS FROM v_execution_time)::INTEGER;

    v_test_passed := (v_execution_time <= v_threshold);

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        4,
        'Performance Test (LIMIT 1000, threshold 10s)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        'Execution time: ' || v_execution_time::TEXT || ' (threshold: ' || v_threshold::TEXT || ')',
        v_execution_time_ms
    );

    RAISE NOTICE 'Test 4 — Performance: % — % (threshold: %)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_execution_time,
        v_threshold;
END $$;


-- ===================================================================
-- TEST CASE 5: No NULL start_point (sampled)
-- ===================================================================
-- Every row must have a non-NULL start_point. The anchor term derives
-- start_point from translated.destination_material; if that column
-- allows NULL or the JOIN degrades, NULL start_points would appear.
-- Tested on a 500-row sample to cap execution cost.
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_null_count        BIGINT;
    v_test_passed       BOOLEAN := FALSE;
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    SELECT COUNT(*)
    INTO v_null_count
    FROM (
        SELECT start_point
        FROM perseus.upstream
        LIMIT 500
    ) AS sub
    WHERE start_point IS NULL;

    v_test_passed := (v_null_count = 0);

    IF NOT v_test_passed THEN
        v_error_message :=
            'Found ' || v_null_count::TEXT ||
            ' NULL start_point value(s) in 500-row sample';
    END IF;

    v_end_time          := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        5,
        'No NULL start_point (sampled, LIMIT 500)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        COALESCE(v_error_message, 'No NULL start_point values in 500-row sample'),
        v_execution_time_ms
    );

    RAISE NOTICE 'Test 5 — No NULL start_point: % — % NULLs in sample',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_null_count;
END $$;


-- ===================================================================
-- TEST CASE 6: Level is Positive (sampled)
-- ===================================================================
-- The level column starts at 1 in the anchor term and increments by 1
-- at each recursive step. A level <= 0 would indicate a corruption in
-- the CTE seed or arithmetic. Tested on a 500-row sample.
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_bad_count         BIGINT;
    v_test_passed       BOOLEAN := FALSE;
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    SELECT COUNT(*)
    INTO v_bad_count
    FROM (
        SELECT level
        FROM perseus.upstream
        LIMIT 500
    ) AS sub
    WHERE level <= 0;

    v_test_passed := (v_bad_count = 0);

    IF NOT v_test_passed THEN
        v_error_message :=
            'Found ' || v_bad_count::TEXT ||
            ' row(s) with level <= 0 in 500-row sample';
    END IF;

    v_end_time          := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        6,
        'Level is Positive (sampled, LIMIT 500)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        COALESCE(v_error_message, 'All levels >= 1 in 500-row sample'),
        v_execution_time_ms
    );

    RAISE NOTICE 'Test 6 — Level is Positive: % — % row(s) with level <= 0',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_bad_count;
END $$;


-- ===================================================================
-- TEST CASE 7: Path Format Validation (sampled)
-- ===================================================================
-- The anchor term initialises path as '/'::TEXT; each recursive step
-- appends the child node id followed by '/'. Therefore every path in
-- the result must start with '/'. A path that does not start with '/'
-- would indicate a concatenation bug or type coercion issue.
-- Tested on a 500-row sample.
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_bad_count         BIGINT;
    v_test_passed       BOOLEAN := FALSE;
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    SELECT COUNT(*)
    INTO v_bad_count
    FROM (
        SELECT path
        FROM perseus.upstream
        LIMIT 500
    ) AS sub
    WHERE path NOT LIKE '/%';

    v_test_passed := (v_bad_count = 0);

    IF NOT v_test_passed THEN
        v_error_message :=
            'Found ' || v_bad_count::TEXT ||
            ' path(s) not starting with ''/'' in 500-row sample';
    END IF;

    v_end_time          := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        7,
        'Path Format Validation (sampled, LIMIT 500)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        COALESCE(v_error_message, 'All paths start with ''/'' in 500-row sample'),
        v_execution_time_ms
    );

    RAISE NOTICE 'Test 7 — Path Format: % — % path(s) not starting with ''/''',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_bad_count;
END $$;


-- ===================================================================
-- TEST RESULTS
-- ===================================================================

SELECT '=====================================================================' AS separator
UNION ALL
SELECT 'UNIT TEST RESULTS: perseus.upstream'
UNION ALL
SELECT '====================================================================='
UNION ALL
SELECT '';

SELECT
    test_number                                          AS "#",
    test_name                                            AS "Test Case",
    status                                               AS "Status",
    CASE
        WHEN status = 'PASSED'  THEN 'PASS'
        WHEN status = 'FAILED'  THEN 'FAIL'
        WHEN status = 'SKIPPED' THEN 'SKIP'
    END                                                  AS "Result",
    execution_time_ms::TEXT || ' ms'                     AS "Time",
    COALESCE(error_message, '-')                         AS "Notes"
FROM test_results
ORDER BY test_number;

SELECT '';

-- ===================================================================
-- SUMMARY
-- ===================================================================

SELECT '=====================================================================' AS separator
UNION ALL
SELECT 'SUMMARY'
UNION ALL
SELECT '====================================================================='
UNION ALL
SELECT '';

SELECT 'Total Tests : ' || COUNT(*)::TEXT                           AS summary FROM test_results
UNION ALL
SELECT 'Passed      : ' || COUNT(*)::TEXT FROM test_results WHERE status = 'PASSED'
UNION ALL
SELECT 'Failed      : ' || COUNT(*)::TEXT FROM test_results WHERE status = 'FAILED'
UNION ALL
SELECT 'Skipped     : ' || COUNT(*)::TEXT FROM test_results WHERE status = 'SKIPPED';

SELECT '';

-- Overall result
SELECT
    CASE
        WHEN (SELECT COUNT(*) FROM test_results WHERE status = 'FAILED') > 0
            THEN 'OVERALL: FAILED'
        WHEN (SELECT COUNT(*) FROM test_results WHERE status = 'PASSED') = 0
            THEN 'OVERALL: ALL TESTS SKIPPED'
        ELSE
            'OVERALL: ALL TESTS PASSED'
    END AS overall_result;

SELECT '';
SELECT '=====================================================================' AS separator;

-- ===================================================================
-- CLEANUP
-- ===================================================================

DROP TABLE test_results;
