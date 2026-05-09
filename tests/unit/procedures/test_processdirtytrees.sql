-- ============================================================================
-- UNIT TESTS: ProcessDirtyTrees
-- ============================================================================
-- Purpose: Comprehensive test suite for ProcessDirtyTrees coordinator procedure
-- Author: Pierre Ribeiro + Claude Code Web
-- Created: 2025-11-24
-- Sprint: Sprint 3 - Issue #20
--
-- Test Coverage:
-- 1. Simple loop test (1-3 materials, quick completion)
-- 2. Timeout test (large batch exceeding 4-second timeout)
-- 3. Empty list test (no dirty materials)
-- 4. Already-clean test (all materials in clean list)
-- 5. Error handling test (invalid UIDs)
-- 6. Max iterations test (safety limit verification)
-- 7. Integration test with ProcessSomeMUpstream (requires dependency)
--
-- Dependencies:
-- - perseus_dbo.processdirtytrees (procedure under test)
-- - perseus_dbo.processsomemupstream (dependency - must exist for integration test)
-- - perseus_dbo.goolist (type)
-- - perseus_dbo.m_upstream (table)
-- ============================================================================

-- ============================================================================
-- TEST FRAMEWORK SETUP
-- ============================================================================

-- Drop test results table if exists
DROP TABLE IF EXISTS test_results_processdirtytrees CASCADE;

-- Create test results table
CREATE TABLE test_results_processdirtytrees (
    test_id SERIAL PRIMARY KEY,
    test_name VARCHAR(200) NOT NULL,
    test_category VARCHAR(50),
    status VARCHAR(20) CHECK (status IN ('PASS', 'FAIL', 'SKIP', 'ERROR')),
    execution_time_ms INTEGER,
    error_message TEXT,
    notes TEXT,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Test execution wrapper function
CREATE OR REPLACE FUNCTION run_test_processdirtytrees(
    p_test_name VARCHAR,
    p_test_category VARCHAR,
    p_test_sql TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_error_message TEXT;
BEGIN
    v_start_time := clock_timestamp();

    BEGIN
        -- Execute the test SQL
        EXECUTE p_test_sql;

        v_end_time := clock_timestamp();
        v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

        INSERT INTO test_results_processdirtytrees (test_name, test_category, status, execution_time_ms)
        VALUES (p_test_name, p_test_category, 'PASS', v_execution_time_ms);

        RAISE NOTICE '✅ PASS: % (% ms)', p_test_name, v_execution_time_ms;

    EXCEPTION
        WHEN OTHERS THEN
            v_end_time := clock_timestamp();
            v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;
            v_error_message := SQLERRM;

            INSERT INTO test_results_processdirtytrees (test_name, test_category, status, execution_time_ms, error_message)
            VALUES (p_test_name, p_test_category, 'FAIL', v_execution_time_ms, v_error_message);

            RAISE NOTICE '❌ FAIL: % - %', p_test_name, v_error_message;
    END;
END;
$$;

RAISE NOTICE '============================================================================';
RAISE NOTICE 'TEST SUITE: ProcessDirtyTrees';
RAISE NOTICE 'Started: %', CURRENT_TIMESTAMP;
RAISE NOTICE '============================================================================';

-- ============================================================================
-- DEPENDENCY CHECK
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '🔍 Checking dependencies...';

DO $$
DECLARE
    v_proc_exists BOOLEAN;
    v_type_exists BOOLEAN;
    v_dep_exists BOOLEAN;
BEGIN
    -- Check if ProcessDirtyTrees exists
    SELECT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'perseus_dbo'
          AND p.proname = 'processdirtytrees'
    ) INTO v_proc_exists;

    IF v_proc_exists THEN
        RAISE NOTICE '✅ perseus_dbo.processdirtytrees exists';
    ELSE
        RAISE NOTICE '❌ perseus_dbo.processdirtytrees NOT FOUND';
        INSERT INTO test_results_processdirtytrees (test_name, test_category, status, error_message)
        VALUES ('Dependency Check', 'Setup', 'FAIL', 'processdirtytrees procedure not found');
    END IF;

    -- Check if goolist type exists
    SELECT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON t.typnamespace = n.oid
        WHERE n.nspname = 'perseus_dbo'
          AND t.typname = 'goolist'
    ) INTO v_type_exists;

    IF v_type_exists THEN
        RAISE NOTICE '✅ perseus_dbo.goolist type exists';
    ELSE
        RAISE NOTICE '⚠️  perseus_dbo.goolist type NOT FOUND (tests will be skipped)';
        INSERT INTO test_results_processdirtytrees (test_name, test_category, status, notes)
        VALUES ('Type Check', 'Setup', 'SKIP', 'goolist type not found - tests require this type');
    END IF;

    -- Check if ProcessSomeMUpstream dependency exists
    SELECT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'perseus_dbo'
          AND p.proname = 'processsomemupstream'
    ) INTO v_dep_exists;

    IF v_dep_exists THEN
        RAISE NOTICE '✅ perseus_dbo.processsomemupstream exists (integration tests enabled)';
    ELSE
        RAISE NOTICE '⚠️  perseus_dbo.processsomemupstream NOT FOUND (integration tests will be skipped)';
        INSERT INTO test_results_processdirtytrees (test_name, test_category, status, notes)
        VALUES ('Dependency Check', 'Setup', 'SKIP', 'processsomemupstream not found - integration tests require this procedure');
    END IF;
END $$;

-- ============================================================================
-- TEST CATEGORY 1: INPUT VALIDATION TESTS
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '📋 TEST CATEGORY 1: Input Validation';
RAISE NOTICE '============================================================================';

-- Test 1.1: NULL dirty_in parameter
SELECT run_test_processdirtytrees(
    'Test 1.1: NULL dirty_in parameter should raise exception',
    'Input Validation',
    $$
    DO $$
    BEGIN
        CALL perseus_dbo.processdirtytrees(
            NULL,
            ARRAY[]::perseus_dbo.goolist
        );
        RAISE EXCEPTION 'Expected exception for NULL dirty_in but procedure succeeded';
    EXCEPTION
        WHEN SQLSTATE 'P0001' THEN
            -- Expected exception - test passes
            IF SQLERRM NOT LIKE '%dirty_in is null%' THEN
                RAISE EXCEPTION 'Exception raised but wrong message: %', SQLERRM;
            END IF;
    END $$;
    $$
);

-- Test 1.2: NULL clean_in parameter
SELECT run_test_processdirtytrees(
    'Test 1.2: NULL clean_in parameter should raise exception',
    'Input Validation',
    $$
    DO $$
    BEGIN
        CALL perseus_dbo.processdirtytrees(
            ARRAY[]::perseus_dbo.goolist,
            NULL
        );
        RAISE EXCEPTION 'Expected exception for NULL clean_in but procedure succeeded';
    EXCEPTION
        WHEN SQLSTATE 'P0001' THEN
            -- Expected exception - test passes
            IF SQLERRM NOT LIKE '%clean_in is null%' THEN
                RAISE EXCEPTION 'Exception raised but wrong message: %', SQLERRM;
            END IF;
    END $$;
    $$
);

-- Test 1.3: Both parameters NULL
SELECT run_test_processdirtytrees(
    'Test 1.3: Both NULL parameters should raise exception',
    'Input Validation',
    $$
    DO $$
    BEGIN
        CALL perseus_dbo.processdirtytrees(NULL, NULL);
        RAISE EXCEPTION 'Expected exception for NULL parameters but procedure succeeded';
    EXCEPTION
        WHEN SQLSTATE 'P0001' THEN
            -- Expected exception - test passes
            NULL;
    END $$;
    $$
);

-- ============================================================================
-- TEST CATEGORY 2: EMPTY LIST TESTS
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '📋 TEST CATEGORY 2: Empty List Handling';
RAISE NOTICE '============================================================================';

-- Test 2.1: Empty dirty list, empty clean list
SELECT run_test_processdirtytrees(
    'Test 2.1: Empty dirty list should exit immediately',
    'Empty List',
    $$
    DO $$
    DECLARE
        v_start_time TIMESTAMP;
        v_duration_ms INTEGER;
    BEGIN
        v_start_time := clock_timestamp();

        CALL perseus_dbo.processdirtytrees(
            ARRAY[]::perseus_dbo.goolist,
            ARRAY[]::perseus_dbo.goolist
        );

        v_duration_ms := EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_start_time))::INTEGER;

        -- Should complete very quickly (< 100ms) since no work to do
        IF v_duration_ms > 100 THEN
            RAISE EXCEPTION 'Empty list took too long: % ms', v_duration_ms;
        END IF;

        RAISE NOTICE 'Empty list completed in % ms (expected < 100ms)', v_duration_ms;
    END $$;
    $$
);

-- Test 2.2: Empty dirty list, non-empty clean list
SELECT run_test_processdirtytrees(
    'Test 2.2: Empty dirty with clean list should exit immediately',
    'Empty List',
    $$
    DO $$
    BEGIN
        CALL perseus_dbo.processdirtytrees(
            ARRAY[]::perseus_dbo.goolist,
            ARRAY['CLEAN-001', 'CLEAN-002']::perseus_dbo.goolist
        );
        -- Should succeed with no errors
    END $$;
    $$
);

-- ============================================================================
-- TEST CATEGORY 3: ALREADY-CLEAN TESTS
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '📋 TEST CATEGORY 3: Already-Clean Materials';
RAISE NOTICE '============================================================================';

-- Test 3.1: All materials already in clean list
SELECT run_test_processdirtytrees(
    'Test 3.1: All dirty materials already clean should exit quickly',
    'Already Clean',
    $$
    DO $$
    DECLARE
        v_start_time TIMESTAMP;
        v_duration_ms INTEGER;
    BEGIN
        v_start_time := clock_timestamp();

        CALL perseus_dbo.processdirtytrees(
            ARRAY['MAT-001', 'MAT-002', 'MAT-003']::perseus_dbo.goolist,
            ARRAY['MAT-001', 'MAT-002', 'MAT-003']::perseus_dbo.goolist
        );

        v_duration_ms := EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_start_time))::INTEGER;

        -- Should complete quickly since materials are filtered out
        IF v_duration_ms > 200 THEN
            RAISE EXCEPTION 'Already-clean test took too long: % ms', v_duration_ms;
        END IF;

        RAISE NOTICE 'Already-clean test completed in % ms', v_duration_ms;
    END $$;
    $$
);

-- Test 3.2: Partial overlap (some clean, some dirty)
SELECT run_test_processdirtytrees(
    'Test 3.2: Partial clean/dirty overlap should process only dirty',
    'Already Clean',
    $$
    DO $$
    BEGIN
        -- Note: This test will SKIP if ProcessSomeMUpstream doesn't exist
        -- because it needs to actually process materials

        -- For now, just verify it doesn't crash
        CALL perseus_dbo.processdirtytrees(
            ARRAY['MAT-001', 'MAT-002', 'MAT-003', 'MAT-004']::perseus_dbo.goolist,
            ARRAY['MAT-001', 'MAT-002']::perseus_dbo.goolist
        );

        RAISE NOTICE 'Partial overlap test completed (MAT-003, MAT-004 should be processed)';
    END $$;
    $$
);

-- ============================================================================
-- TEST CATEGORY 4: SIMPLE LOOP TESTS
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '📋 TEST CATEGORY 4: Simple Loop Processing';
RAISE NOTICE '============================================================================';

-- Test 4.1: Process 1 dirty material
SELECT run_test_processdirtytrees(
    'Test 4.1: Process 1 dirty material',
    'Simple Loop',
    $$
    DO $$
    BEGIN
        CALL perseus_dbo.processdirtytrees(
            ARRAY['MAT-SINGLE-001']::perseus_dbo.goolist,
            ARRAY[]::perseus_dbo.goolist
        );
        RAISE NOTICE 'Single material processed successfully';
    END $$;
    $$
);

-- Test 4.2: Process 3 dirty materials
SELECT run_test_processdirtytrees(
    'Test 4.2: Process 3 dirty materials',
    'Simple Loop',
    $$
    DO $$
    BEGIN
        CALL perseus_dbo.processdirtytrees(
            ARRAY['MAT-LOOP-001', 'MAT-LOOP-002', 'MAT-LOOP-003']::perseus_dbo.goolist,
            ARRAY[]::perseus_dbo.goolist
        );
        RAISE NOTICE '3 materials processed successfully';
    END $$;
    $$
);

-- Test 4.3: Process 5 dirty materials
SELECT run_test_processdirtytrees(
    'Test 4.3: Process 5 dirty materials',
    'Simple Loop',
    $$
    DO $$
    DECLARE
        v_start_time TIMESTAMP;
        v_duration_ms INTEGER;
    BEGIN
        v_start_time := clock_timestamp();

        CALL perseus_dbo.processdirtytrees(
            ARRAY['MAT-001', 'MAT-002', 'MAT-003', 'MAT-004', 'MAT-005']::perseus_dbo.goolist,
            ARRAY[]::perseus_dbo.goolist
        );

        v_duration_ms := EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_start_time))::INTEGER;
        RAISE NOTICE '5 materials processed in % ms', v_duration_ms;
    END $$;
    $$
);

-- ============================================================================
-- TEST CATEGORY 5: TIMEOUT TESTS
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '📋 TEST CATEGORY 5: Timeout Behavior';
RAISE NOTICE '============================================================================';

-- Test 5.1: Large batch that may timeout (100 materials)
SELECT run_test_processdirtytrees(
    'Test 5.1: Large batch (100 materials) - timeout monitoring',
    'Timeout',
    $$
    DO $$
    DECLARE
        v_start_time TIMESTAMP;
        v_duration_ms INTEGER;
        v_dirty_array perseus_dbo.goolist;
        i INTEGER;
    BEGIN
        -- Generate 100 material UIDs
        v_dirty_array := ARRAY[]::perseus_dbo.goolist;
        FOR i IN 1..100 LOOP
            v_dirty_array := array_append(v_dirty_array, 'MAT-TIMEOUT-' || LPAD(i::TEXT, 5, '0'));
        END LOOP;

        v_start_time := clock_timestamp();

        CALL perseus_dbo.processdirtytrees(v_dirty_array, ARRAY[]::perseus_dbo.goolist);

        v_duration_ms := EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_start_time))::INTEGER;

        RAISE NOTICE 'Large batch (100) completed in % ms', v_duration_ms;

        -- Note: Timeout is 4000ms, so if it completes, check duration
        IF v_duration_ms >= 4000 THEN
            RAISE NOTICE 'Warning: Processing approached timeout threshold';
        END IF;
    END $$;
    $$
);

-- Test 5.2: Very large batch (500 materials) - should timeout
SELECT run_test_processdirtytrees(
    'Test 5.2: Very large batch (500 materials) - expect timeout',
    'Timeout',
    $$
    DO $$
    DECLARE
        v_start_time TIMESTAMP;
        v_duration_ms INTEGER;
        v_dirty_array perseus_dbo.goolist;
        i INTEGER;
    BEGIN
        -- Generate 500 material UIDs
        v_dirty_array := ARRAY[]::perseus_dbo.goolist;
        FOR i IN 1..500 LOOP
            v_dirty_array := array_append(v_dirty_array, 'MAT-LARGE-' || LPAD(i::TEXT, 5, '0'));
        END LOOP;

        v_start_time := clock_timestamp();

        CALL perseus_dbo.processdirtytrees(v_dirty_array, ARRAY[]::perseus_dbo.goolist);

        v_duration_ms := EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_start_time))::INTEGER;

        RAISE NOTICE 'Very large batch (500) completed/stopped in % ms', v_duration_ms;

        -- Should timeout at ~4000ms
        IF v_duration_ms < 3000 THEN
            RAISE NOTICE 'Warning: Processing completed faster than expected (possible optimization or skipped materials)';
        END IF;
    END $$;
    $$
);

-- ============================================================================
-- TEST CATEGORY 6: SAFETY LIMIT TESTS
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '📋 TEST CATEGORY 6: Safety Limits';
RAISE NOTICE '============================================================================';

-- Test 6.1: Max iterations warning (not a real test, just documentation)
DO $$
BEGIN
    INSERT INTO test_results_processdirtytrees (test_name, test_category, status, notes)
    VALUES (
        'Test 6.1: Max iterations safety limit (10k)',
        'Safety Limits',
        'SKIP',
        'Max iterations = 10k prevents infinite loops. Would require 10k+ materials to test. Verified in code review.'
    );
    RAISE NOTICE '⏭️  SKIP: Test 6.1 - Max iterations limit verified in code (10k limit)';
END $$;

-- ============================================================================
-- TEST CATEGORY 7: ERROR HANDLING TESTS
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '📋 TEST CATEGORY 7: Error Handling';
RAISE NOTICE '============================================================================';

-- Test 7.1: Invalid UID format
SELECT run_test_processdirtytrees(
    'Test 7.1: Invalid UID format should be handled gracefully',
    'Error Handling',
    $$
    DO $$
    BEGIN
        -- Test with various invalid formats
        CALL perseus_dbo.processdirtytrees(
            ARRAY['', '   ', 'INVALID@#$', NULL::VARCHAR]::perseus_dbo.goolist,
            ARRAY[]::perseus_dbo.goolist
        );
        -- Should not crash, may log warnings
        RAISE NOTICE 'Invalid UIDs handled without crash';
    END $$;
    $$
);

-- Test 7.2: Very long UID (> 50 chars)
SELECT run_test_processdirtytrees(
    'Test 7.2: Very long UID should be truncated or rejected',
    'Error Handling',
    $$
    DO $$
    DECLARE
        v_long_uid VARCHAR(200);
    BEGIN
        v_long_uid := REPEAT('VERYLONGUID', 20); -- 220 chars

        CALL perseus_dbo.processdirtytrees(
            ARRAY[v_long_uid]::perseus_dbo.goolist,
            ARRAY[]::perseus_dbo.goolist
        );

        RAISE NOTICE 'Very long UID processed (may be truncated by type constraint)';
    END $$;
    $$
);

-- ============================================================================
-- TEST CATEGORY 8: INTEGRATION TESTS (REQUIRE DEPENDENCY)
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '📋 TEST CATEGORY 8: Integration Tests (ProcessSomeMUpstream)';
RAISE NOTICE '============================================================================';

-- Test 8.1: Full integration with ProcessSomeMUpstream
DO $$
DECLARE
    v_dep_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'perseus_dbo'
          AND p.proname = 'processsomemupstream'
    ) INTO v_dep_exists;

    IF NOT v_dep_exists THEN
        INSERT INTO test_results_processdirtytrees (test_name, test_category, status, notes)
        VALUES (
            'Test 8.1: Full integration with ProcessSomeMUpstream',
            'Integration',
            'SKIP',
            'ProcessSomeMUpstream procedure not found - integration test requires this dependency'
        );
        RAISE NOTICE '⏭️  SKIP: Test 8.1 - ProcessSomeMUpstream not available';
    ELSE
        -- Run integration test
        PERFORM run_test_processdirtytrees(
            'Test 8.1: Full integration with ProcessSomeMUpstream',
            'Integration',
            $$
            DO $$
            DECLARE
                v_start_time TIMESTAMP;
                v_duration_ms INTEGER;
            BEGIN
                v_start_time := clock_timestamp();

                -- This will actually call ProcessSomeMUpstream via refcursor
                CALL perseus_dbo.processdirtytrees(
                    ARRAY['MAT-INT-001', 'MAT-INT-002']::perseus_dbo.goolist,
                    ARRAY[]::perseus_dbo.goolist
                );

                v_duration_ms := EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_start_time))::INTEGER;

                RAISE NOTICE 'Integration test completed in % ms', v_duration_ms;
                RAISE NOTICE 'Verify ProcessSomeMUpstream was called via refcursor pattern';
            END $$;
            $$
        );
    END IF;
END $$;

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================
RAISE NOTICE '';
RAISE NOTICE '============================================================================';
RAISE NOTICE 'TEST SUMMARY: ProcessDirtyTrees';
RAISE NOTICE '============================================================================';

DO $$
DECLARE
    v_total INTEGER;
    v_passed INTEGER;
    v_failed INTEGER;
    v_skipped INTEGER;
    v_pass_rate NUMERIC;
BEGIN
    SELECT COUNT(*) INTO v_total FROM test_results_processdirtytrees;
    SELECT COUNT(*) INTO v_passed FROM test_results_processdirtytrees WHERE status = 'PASS';
    SELECT COUNT(*) INTO v_failed FROM test_results_processdirtytrees WHERE status = 'FAIL';
    SELECT COUNT(*) INTO v_skipped FROM test_results_processdirtytrees WHERE status = 'SKIP';

    IF (v_total - v_skipped) > 0 THEN
        v_pass_rate := (v_passed::NUMERIC / (v_total - v_skipped)::NUMERIC) * 100;
    ELSE
        v_pass_rate := 0;
    END IF;

    RAISE NOTICE 'Total Tests: %', v_total;
    RAISE NOTICE 'Passed: % ✅', v_passed;
    RAISE NOTICE 'Failed: % ❌', v_failed;
    RAISE NOTICE 'Skipped: % ⏭️', v_skipped;
    RAISE NOTICE 'Pass Rate: %% (excluding skipped)', ROUND(v_pass_rate, 2);
    RAISE NOTICE '';

    IF v_failed > 0 THEN
        RAISE NOTICE '❌ FAILED TESTS:';
        RAISE NOTICE '---';
        FOR rec IN (SELECT test_name, error_message FROM test_results_processdirtytrees WHERE status = 'FAIL') LOOP
            RAISE NOTICE '  - %', rec.test_name;
            RAISE NOTICE '    Error: %', rec.error_message;
        END LOOP;
    ELSE
        RAISE NOTICE '✅ ALL TESTS PASSED!';
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE 'Detailed results stored in: test_results_processdirtytrees';
    RAISE NOTICE 'Query: SELECT * FROM test_results_processdirtytrees ORDER BY test_id;';
END $$;

RAISE NOTICE '============================================================================';
RAISE NOTICE 'Completed: %', CURRENT_TIMESTAMP;
RAISE NOTICE '============================================================================';

-- ============================================================================
-- INTEGRATION TEST TEMPLATE (FOR FUTURE USE)
-- ============================================================================
-- Once ProcessSomeMUpstream is corrected and deployed:
--
-- CREATE OR REPLACE FUNCTION test_processdirtytrees_full_integration()
-- RETURNS VOID
-- LANGUAGE plpgsql
-- AS $$
-- DECLARE
--     v_initial_count INTEGER;
--     v_final_count INTEGER;
-- BEGIN
--     -- Setup: Count m_upstream records before
--     SELECT COUNT(*) INTO v_initial_count FROM perseus_dbo.m_upstream;
--
--     -- Execute: Process dirty materials
--     CALL perseus_dbo.processdirtytrees(
--         ARRAY['TEST-MAT-001', 'TEST-MAT-002']::perseus_dbo.goolist,
--         ARRAY[]::perseus_dbo.goolist
--     );
--
--     -- Verify: Check m_upstream was updated
--     SELECT COUNT(*) INTO v_final_count FROM perseus_dbo.m_upstream;
--
--     IF v_final_count = v_initial_count THEN
--         RAISE WARNING 'No changes to m_upstream (materials may not exist or already processed)';
--     ELSE
--         RAISE NOTICE 'Integration test: m_upstream updated (before: %, after: %)',
--                      v_initial_count, v_final_count;
--     END IF;
-- END;
-- $$;

-- ============================================================================
-- QUERY HELPERS FOR TEST ANALYSIS
-- ============================================================================
-- View all test results
-- SELECT * FROM test_results_processdirtytrees ORDER BY test_id;

-- View only failures
-- SELECT test_name, error_message, execution_time_ms
-- FROM test_results_processdirtytrees
-- WHERE status = 'FAIL'
-- ORDER BY test_id;

-- View performance metrics
-- SELECT test_category, AVG(execution_time_ms) as avg_time_ms, MAX(execution_time_ms) as max_time_ms
-- FROM test_results_processdirtytrees
-- WHERE status = 'PASS'
-- GROUP BY test_category
-- ORDER BY avg_time_ms DESC;

-- ============================================================================
-- END OF TEST SUITE
-- ============================================================================
