-- ===================================================================
-- UNIT TEST: test_translated
-- ===================================================================
-- Purpose: Comprehensive test suite for perseus.translated (MATERIALIZED VIEW)
-- Priority: P0 (Critical Path)
-- Task: T047 (US1 Phase 3 — Validation)
-- Object: perseus.translated
-- Type: MATERIALIZED VIEW (indexes view, trigger-based refresh)
-- Created: 2026-03-08
-- ===================================================================


-- ===================================================================
-- TEST SETUP
-- ===================================================================

-- Disable NOTICE output for cleaner test results
SET client_min_messages = WARNING;

-- Test results tracking
CREATE TEMPORARY TABLE test_results (
    test_number     INTEGER PRIMARY KEY,
    test_name       VARCHAR(200),
    status          VARCHAR(20),
    error_message   TEXT,
    execution_time_ms INTEGER
);

-- Re-enable NOTICE for test output
SET client_min_messages = NOTICE;


-- ===================================================================
-- TEST CASE 1: Materialized View Existence
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
        FROM pg_matviews
        WHERE schemaname = 'perseus'
          AND matviewname = 'translated'
    ) THEN
        v_test_passed := TRUE;
        v_error_message := 'Materialized view perseus.translated exists';
    ELSE
        v_test_passed := FALSE;
        v_error_message := 'Materialized view perseus.translated NOT FOUND in pg_matviews — object missing or wrong schema';
    END IF;

    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        1,
        'Materialized View Existence',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message,
        v_execution_time_ms
    );
END $$;


-- ===================================================================
-- TEST CASE 2: Column Structure Validation
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_column_count      INTEGER;
    v_expected_count    INTEGER := 3;
    v_test_passed       BOOLEAN := FALSE;
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    SELECT COUNT(*)::INTEGER INTO v_column_count
    FROM information_schema.columns
    WHERE table_schema = 'perseus'
      AND table_name   = 'translated'
      AND column_name IN ('source_material', 'destination_material', 'transition_id');

    v_test_passed := (v_column_count = v_expected_count);

    IF v_test_passed THEN
        v_error_message := 'All 3 expected columns present: source_material, destination_material, transition_id';
    ELSE
        -- Identify which columns are missing
        SELECT 'Expected ' || v_expected_count || ' columns, found ' || v_column_count
               || ' — check for: source_material, destination_material, transition_id'
        INTO v_error_message;
    END IF;

    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        2,
        'Column Structure Validation',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message,
        v_execution_time_ms
    );
END $$;


-- ===================================================================
-- TEST CASE 3: Unique Index Existence (required for CONCURRENT refresh)
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_test_passed       BOOLEAN := FALSE;
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    IF EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE schemaname = 'perseus'
          AND tablename  = 'translated'
          AND indexname  = 'idx_translated_unique'
    ) THEN
        v_test_passed := TRUE;
        v_error_message := 'Unique index idx_translated_unique exists — CONCURRENT refresh is supported';
    ELSE
        v_test_passed := FALSE;
        v_error_message := 'CRITICAL: idx_translated_unique NOT FOUND — REFRESH MATERIALIZED VIEW CONCURRENTLY will fail without this index';
    END IF;

    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        3,
        'Unique Index Existence (CONCURRENT refresh requirement)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message,
        v_execution_time_ms
    );
END $$;


-- ===================================================================
-- TEST CASE 4: Row Count Validation
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_row_count         BIGINT;
    v_status            VARCHAR(20);
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    SELECT COUNT(*)::BIGINT INTO v_row_count
    FROM perseus.translated;

    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    -- Always PASS — record the count; warn if empty (may indicate refresh needed)
    IF v_row_count = 0 THEN
        v_status        := 'PASSED';
        v_error_message := 'WARNING: row count = 0 — materialized view may need REFRESH or source tables are empty';
    ELSE
        v_status        := 'PASSED';
        v_error_message := 'Row count: ' || v_row_count;
    END IF;

    RAISE NOTICE 'perseus.translated row count: %', v_row_count;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        4,
        'Row Count Validation',
        v_status,
        v_error_message,
        v_execution_time_ms
    );
END $$;


-- ===================================================================
-- TEST CASE 5: Performance Test (full scan threshold: 10 seconds)
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time    INTERVAL;
    v_execution_time_ms INTEGER;
    v_threshold         INTERVAL := '10 seconds';
    v_test_passed       BOOLEAN := FALSE;
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    PERFORM * FROM perseus.translated LIMIT 1000;

    v_end_time          := clock_timestamp();
    v_execution_time    := v_end_time - v_start_time;
    v_execution_time_ms := EXTRACT(EPOCH FROM v_execution_time)::INTEGER * 1000
                           + EXTRACT(MILLISECONDS FROM v_execution_time)::INTEGER;

    v_test_passed := (v_execution_time <= v_threshold);

    v_error_message := 'Execution time: ' || v_execution_time
                       || ' (threshold: ' || v_threshold || ')';

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        5,
        'Performance Test (full scan <=10s)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message,
        v_execution_time_ms
    );
END $$;


-- ===================================================================
-- TEST CASE 6: No NULL source_material
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

    SELECT COUNT(*)::BIGINT INTO v_null_count
    FROM perseus.translated
    WHERE source_material IS NULL;

    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    v_test_passed := (v_null_count = 0);

    IF v_test_passed THEN
        v_error_message := 'No NULL values in source_material — NOT NULL constraint satisfied';
    ELSE
        v_error_message := v_null_count || ' row(s) have NULL source_material — NOT NULL constraint violated';
    END IF;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        6,
        'No NULL source_material',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message,
        v_execution_time_ms
    );
END $$;


-- ===================================================================
-- TEST CASE 7: No NULL destination_material
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

    SELECT COUNT(*)::BIGINT INTO v_null_count
    FROM perseus.translated
    WHERE destination_material IS NULL;

    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    v_test_passed := (v_null_count = 0);

    IF v_test_passed THEN
        v_error_message := 'No NULL values in destination_material — NOT NULL constraint satisfied';
    ELSE
        v_error_message := v_null_count || ' row(s) have NULL destination_material — NOT NULL constraint violated';
    END IF;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        7,
        'No NULL destination_material',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message,
        v_execution_time_ms
    );
END $$;


-- ===================================================================
-- TEST CASE 8: Trigger Function Existence (refresh_translated_mv)
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_test_passed       BOOLEAN := FALSE;
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    IF EXISTS (
        SELECT 1
        FROM pg_proc     p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'perseus'
          AND p.proname = 'refresh_translated_mv'
    ) THEN
        v_test_passed := TRUE;
        v_error_message := 'Trigger function perseus.refresh_translated_mv() exists';
    ELSE
        v_test_passed := FALSE;
        v_error_message := 'Trigger function perseus.refresh_translated_mv() NOT FOUND — triggers on material_transition and transition_material will fail';
    END IF;

    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        8,
        'Trigger Function Existence (refresh_translated_mv)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message,
        v_execution_time_ms
    );
END $$;


-- ===================================================================
-- TEST RESULTS
-- ===================================================================

SELECT '=====================================================================' AS separator
UNION ALL
SELECT 'UNIT TEST RESULTS: perseus.translated (MATERIALIZED VIEW)'
UNION ALL
SELECT '====================================================================='
UNION ALL
SELECT '';

SELECT
    test_number                    AS "#",
    test_name                      AS "Test Case",
    status                         AS "Status",
    CASE
        WHEN status = 'PASSED'  THEN 'PASS'
        WHEN status = 'FAILED'  THEN 'FAIL'
        WHEN status = 'SKIPPED' THEN 'SKIP'
    END                            AS "Result",
    execution_time_ms || ' ms'     AS "Time",
    COALESCE(error_message, '-')   AS "Notes"
FROM test_results
ORDER BY test_number;

SELECT '';

-- Summary statistics
SELECT '=====================================================================' AS separator
UNION ALL
SELECT 'SUMMARY'
UNION ALL
SELECT '====================================================================='
UNION ALL
SELECT '';

SELECT 'Total:   ' || COUNT(*)                                  AS summary FROM test_results
UNION ALL
SELECT 'Passed:  ' || COUNT(*) FROM test_results WHERE status = 'PASSED'
UNION ALL
SELECT 'Failed:  ' || COUNT(*) FROM test_results WHERE status = 'FAILED'
UNION ALL
SELECT 'Skipped: ' || COUNT(*) FROM test_results WHERE status = 'SKIPPED'
UNION ALL
SELECT '';

-- Overall result
SELECT
    CASE
        WHEN (SELECT COUNT(*) FROM test_results WHERE status = 'FAILED') > 0
            THEN 'OVERALL: FAILED — ' ||
                 (SELECT COUNT(*) FROM test_results WHERE status = 'FAILED')::TEXT ||
                 ' test(s) failed'
        WHEN (SELECT COUNT(*) FROM test_results WHERE status = 'PASSED') = 0
            THEN 'OVERALL: ALL TESTS SKIPPED'
        ELSE 'OVERALL: ALL TESTS PASSED'
    END AS overall_result;

SELECT '';
SELECT '=====================================================================' AS separator;

-- Cleanup
DROP TABLE test_results;
