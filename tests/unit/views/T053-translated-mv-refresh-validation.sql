-- ===================================================================
-- VALIDATION: T053 - Translated MV Refresh Validation
-- ===================================================================
-- Purpose: Validate CONCURRENT refresh mechanism for perseus.translated
-- Task: T053 (US1 Phase 3 — Validation)
-- Requirement: CONCURRENT refresh requires idx_translated_unique
-- Thresholds: Refresh < 30s (DEV), triggers active on both source tables
-- Created: 2026-03-08
-- ===================================================================
--
-- Test Coverage:
--   1. Unique Index Presence          — idx_translated_unique in pg_indexes
--   2. Trigger on material_transition — trigger name LIKE '%translated%'
--   3. Trigger on transition_material — trigger name LIKE '%translated%'
--   4. CONCURRENT Refresh Execution   — timed, threshold 30 seconds
--   5. Post-Refresh Row Count         — always PASS, record count
--
-- Dependencies:
--   - perseus.translated (materialized view — must exist and be populated)
--   - idx_translated_unique (required for CONCURRENT refresh)
--   - perseus.refresh_translated_mv() (trigger function)
--
-- Notes:
--   - Test 4 executes a live REFRESH MATERIALIZED VIEW CONCURRENTLY.
--     This acquires an ExclusiveLock momentarily; safe in DEV.
--     Do NOT run during peak-load windows in STAGING/PROD.
--   - Test 4 uses EXCEPTION WHEN OTHERS to catch the case where
--     idx_translated_unique is missing, which causes CONCURRENTLY to fail
--     with "ERROR: cannot refresh materialized view concurrently without
--     a unique index". The exception is recorded as FAILED with the
--     original error message preserved.
-- ===================================================================


-- ===================================================================
-- TEST SETUP
-- ===================================================================

-- Suppress NOTICE output during temp table creation
SET client_min_messages = WARNING;

CREATE TEMPORARY TABLE test_results (
    test_number       INTEGER       PRIMARY KEY,
    test_name         VARCHAR(200)  NOT NULL,
    status            VARCHAR(20)   NOT NULL,
    error_message     TEXT,
    execution_time_ms INTEGER
);

-- Restore NOTICE so test progress is visible
SET client_min_messages = NOTICE;


-- ===================================================================
-- TEST CASE 1: Unique Index Presence
-- ===================================================================
-- CONCURRENT refresh requires at least one unique index on the MV.
-- idx_translated_unique covers (source_material, destination_material,
-- transition_id). Without this index, REFRESH ... CONCURRENTLY raises
-- an error and the MV cannot be refreshed without locking reads.
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_index_count       INTEGER;
    v_test_passed       BOOLEAN := FALSE;
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    SELECT COUNT(*)::INTEGER
    INTO v_index_count
    FROM pg_indexes
    WHERE schemaname = 'perseus'
      AND tablename  = 'translated'
      AND indexname  = 'idx_translated_unique';

    v_test_passed := (v_index_count = 1);

    IF v_test_passed THEN
        v_error_message :=
            'idx_translated_unique present on perseus.translated'
            || ' — CONCURRENT refresh is supported';
    ELSE
        v_error_message :=
            'CRITICAL: idx_translated_unique NOT FOUND on perseus.translated'
            || ' — REFRESH MATERIALIZED VIEW CONCURRENTLY will fail';
    END IF;

    v_end_time          := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        1,
        'Unique Index Presence (idx_translated_unique)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message,
        v_execution_time_ms
    );

    RAISE NOTICE 'Test 1 — Unique Index Presence: %',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED — ' || v_error_message END;
END $$;


-- ===================================================================
-- TEST CASE 2: Trigger on material_transition
-- ===================================================================
-- The MV refresh mechanism requires an AFTER INSERT/UPDATE/DELETE
-- trigger on perseus.material_transition that calls
-- perseus.refresh_translated_mv(). The trigger name is expected to
-- contain 'translated' but may carry any suffix — the LIKE predicate
-- accepts any matching trigger name.
-- PASS condition: at least 1 matching trigger exists.
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_trigger_count     INTEGER;
    v_test_passed       BOOLEAN := FALSE;
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    SELECT COUNT(*)::INTEGER
    INTO v_trigger_count
    FROM information_schema.triggers
    WHERE trigger_schema      = 'perseus'
      AND event_object_table  = 'material_transition'
      AND trigger_name        LIKE '%translated%';

    v_test_passed := (v_trigger_count >= 1);

    IF v_test_passed THEN
        v_error_message :=
            v_trigger_count::TEXT
            || ' trigger(s) matching ''%translated%'' found on perseus.material_transition';
    ELSE
        v_error_message :=
            'No trigger matching ''%translated%'' found on perseus.material_transition'
            || ' — MV will not auto-refresh when material_transition is modified';
    END IF;

    v_end_time          := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        2,
        'Trigger on material_transition (LIKE ''%translated%'')',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message,
        v_execution_time_ms
    );

    RAISE NOTICE 'Test 2 — Trigger on material_transition: % (% trigger(s) found)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_trigger_count;
END $$;


-- ===================================================================
-- TEST CASE 3: Trigger on transition_material
-- ===================================================================
-- Same requirement as Test 2 but for perseus.transition_material.
-- Both source tables must have triggers to ensure the MV stays
-- consistent after writes to either table.
-- PASS condition: at least 1 matching trigger exists.
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_trigger_count     INTEGER;
    v_test_passed       BOOLEAN := FALSE;
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    SELECT COUNT(*)::INTEGER
    INTO v_trigger_count
    FROM information_schema.triggers
    WHERE trigger_schema      = 'perseus'
      AND event_object_table  = 'transition_material'
      AND trigger_name        LIKE '%translated%';

    v_test_passed := (v_trigger_count >= 1);

    IF v_test_passed THEN
        v_error_message :=
            v_trigger_count::TEXT
            || ' trigger(s) matching ''%translated%'' found on perseus.transition_material';
    ELSE
        v_error_message :=
            'No trigger matching ''%translated%'' found on perseus.transition_material'
            || ' — MV will not auto-refresh when transition_material is modified';
    END IF;

    v_end_time          := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        3,
        'Trigger on transition_material (LIKE ''%translated%'')',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message,
        v_execution_time_ms
    );

    RAISE NOTICE 'Test 3 — Trigger on transition_material: % (% trigger(s) found)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_trigger_count;
END $$;


-- ===================================================================
-- TEST CASE 4: CONCURRENT Refresh Execution
-- ===================================================================
-- Executes REFRESH MATERIALIZED VIEW CONCURRENTLY against
-- perseus.translated and asserts completion within 30 seconds.
--
-- The 30-second threshold is conservative for DEV data volumes
-- (3,589 rows at time of writing). It guards against:
--   - Missing idx_translated_unique (causes immediate EXCEPTION)
--   - Runaway refresh due to lock contention or planner regression
--
-- EXCEPTION WHEN OTHERS catches the case where idx_translated_unique
-- is absent. The original error message (SQLERRM) is preserved in
-- error_message so the root cause is immediately visible in results.
--
-- NOTE: This test acquires an ExclusiveLock on perseus.translated
-- momentarily. Safe in DEV. Do NOT run during peak-load windows
-- in STAGING or PROD — schedule during low-traffic periods instead.
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time    INTERVAL;
    v_execution_time_ms INTEGER;
    v_threshold         INTERVAL := INTERVAL '30 seconds';
    v_test_passed       BOOLEAN  := FALSE;
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    BEGIN
        REFRESH MATERIALIZED VIEW CONCURRENTLY perseus.translated;

        v_end_time          := clock_timestamp();
        v_execution_time    := v_end_time - v_start_time;
        v_execution_time_ms := EXTRACT(EPOCH FROM v_execution_time)::INTEGER * 1000
                               + EXTRACT(MILLISECONDS FROM v_execution_time)::INTEGER;

        v_test_passed := (v_execution_time <= v_threshold);

        v_error_message :=
            'Execution time: ' || v_execution_time::TEXT
            || ' (threshold: ' || v_threshold::TEXT || ')';

    EXCEPTION WHEN OTHERS THEN
        v_end_time          := clock_timestamp();
        v_execution_time    := v_end_time - v_start_time;
        v_execution_time_ms := EXTRACT(EPOCH FROM v_execution_time)::INTEGER * 1000
                               + EXTRACT(MILLISECONDS FROM v_execution_time)::INTEGER;

        v_test_passed   := FALSE;
        v_error_message :=
            'REFRESH MATERIALIZED VIEW CONCURRENTLY raised an exception: '
            || SQLERRM
            || ' — verify idx_translated_unique exists on perseus.translated';
    END;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        4,
        'CONCURRENT Refresh Execution (threshold 30s)',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message,
        v_execution_time_ms
    );

    RAISE NOTICE 'Test 4 — CONCURRENT Refresh: % — %',
        CASE WHEN v_test_passed THEN 'PASSED' ELSE 'FAILED' END,
        v_error_message;
END $$;


-- ===================================================================
-- TEST CASE 5: Post-Refresh Row Count
-- ===================================================================
-- Counts all rows in perseus.translated after the refresh in Test 4.
-- This test always PASSES — the purpose is to record the post-refresh
-- row count as a regression baseline. A count of 0 triggers a WARNING
-- note (may indicate empty source tables or a failed prior refresh),
-- but does not cause a FAILED result.
-- ===================================================================
DO $$
DECLARE
    v_start_time        TIMESTAMP;
    v_end_time          TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_row_count         BIGINT;
    v_error_message     TEXT;
BEGIN
    v_start_time := clock_timestamp();

    SELECT COUNT(*)::BIGINT
    INTO v_row_count
    FROM perseus.translated;

    v_end_time          := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    -- Always PASS — record count; warn if empty
    IF v_row_count = 0 THEN
        v_error_message :=
            'WARNING: post-refresh row count = 0'
            || ' — source tables may be empty or refresh (Test 4) did not complete successfully';
    ELSE
        v_error_message :=
            'Post-refresh row count: ' || v_row_count::TEXT
            || ' — count >= 0 satisfied';
    END IF;

    RAISE NOTICE 'Test 5 — Post-Refresh Row Count: PASSED — % row(s)', v_row_count;

    INSERT INTO test_results (test_number, test_name, status, error_message, execution_time_ms)
    VALUES (
        5,
        'Post-Refresh Row Count',
        'PASSED',
        v_error_message,
        v_execution_time_ms
    );
END $$;


-- ===================================================================
-- TEST RESULTS
-- ===================================================================

SELECT '=====================================================================' AS separator
UNION ALL
SELECT 'VALIDATION RESULTS: T053 — Translated MV Refresh Validation'
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

SELECT 'Total Tests : ' || COUNT(*)::TEXT                            AS summary FROM test_results
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
            THEN 'OVERALL: FAILED — '
                 || (SELECT COUNT(*) FROM test_results WHERE status = 'FAILED')::TEXT
                 || ' test(s) failed'
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
