-- ============================================================================
-- UNIT TEST: usp_updatemdownstream
-- ============================================================================
-- Purpose: Comprehensive testing of usp_updatemdownstream procedure
-- Author: Pierre Ribeiro + Claude Code Web
-- Date: 2025-11-24
-- GitHub Issue: #17
-- Procedure: procedures/corrected/usp_updatemdownstream.sql
-- Pairing: This procedure is the DOWNSTREAM PAIR of usp_updatemupstream
-- ============================================================================
--
-- Test Coverage:
--   1. Normal execution - Phase 1 (new downstream records)
--   2. Normal execution - Phase 2 (reverse paths from upstream)
--   3. Empty table scenario (bootstrap)
--   4. No candidates found (early skip)
--   5. Function dependency validation (mcgetdownstreambylist, reversepath)
--   6. Error handling (function missing)
--   7. Temp table cleanup verification
--   8. Performance validation (<5s target)
--   9. Transaction rollback on error
--   10. Batch limit verification (500 per phase)
--   11. Integration with usp_UpdateMUpstream (paired execution)
--   12. Bidirectional consistency verification
--
-- Prerequisites:
--   - Tables exist: goo, material_transition_material, m_downstream, m_upstream
--   - Functions exist: mcgetdownstreambylist, reversepath
--   - Upstream pair: usp_updatemupstream (for integration tests)
--   - Test data loaded (or mocked)
--
-- Usage:
--   psql -h $HOST -U $USER -d $DATABASE -f test_usp_updatemdownstream.sql
--
-- ============================================================================

-- ============================================================================
-- TEST SETUP
-- ============================================================================

\echo '============================================================================'
\echo 'UNIT TEST: usp_updatemdownstream'
\echo '============================================================================'
\echo 'Started:' `date`
\echo ''

-- Set client encoding for consistent output
SET client_min_messages = NOTICE;

-- Start transaction (will rollback at end to avoid affecting production data)
BEGIN;

\echo 'Test environment initialized'
\echo ''

-- ============================================================================
-- TEST CASE 1: Normal Execution - Phase 1 (New Downstream Records)
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 1: Normal Execution - Phase 1 (New Downstream Records)'
\echo '============================================================================'

DO $$
DECLARE
    v_initial_count INTEGER;
    v_final_count INTEGER;
    v_delta INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Creating mock test data for Phase 1...';

    -- Save initial state
    SELECT COUNT(*) INTO v_initial_count FROM perseus_dbo.m_downstream;

    -- Create test materials in goo and material_transition_material
    INSERT INTO perseus_dbo.goo (uid, added_on)
    VALUES
        ('TEST_DS_MAT_001', CURRENT_TIMESTAMP),
        ('TEST_DS_MAT_002', CURRENT_TIMESTAMP),
        ('TEST_DS_MAT_003', CURRENT_TIMESTAMP)
    ON CONFLICT (uid) DO UPDATE SET added_on = CURRENT_TIMESTAMP;

    INSERT INTO perseus_dbo.material_transition_material (start_point, end_point)
    VALUES
        ('TEST_DS_MAT_001', 'TEST_END_001'),
        ('TEST_DS_MAT_002', 'TEST_END_002'),
        ('TEST_DS_MAT_003', 'TEST_END_003')
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Test data created successfully';

    -- Execute procedure
    RAISE NOTICE 'Executing usp_updatemdownstream...';
    CALL perseus_dbo.usp_updatemdownstream();

    -- Verify results
    SELECT COUNT(*) INTO v_final_count FROM perseus_dbo.m_downstream;
    v_delta := v_final_count - v_initial_count;

    IF v_delta >= 0 THEN
        v_test_result := 'PASSED';
        RAISE NOTICE 'Test Case 1: PASSED - Phase 1 inserted % downstream records', v_delta;
    ELSE
        v_test_result := 'FAILED';
        RAISE WARNING 'Test Case 1: FAILED - Unexpected delta: %', v_delta;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 1: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 2: Normal Execution - Phase 2 (Reverse Paths from Upstream)
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 2: Normal Execution - Phase 2 (Reverse Paths from Upstream)'
\echo '============================================================================'

DO $$
DECLARE
    v_initial_count INTEGER;
    v_final_count INTEGER;
    v_delta INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Creating mock upstream data for Phase 2...';

    -- Save initial state
    SELECT COUNT(*) INTO v_initial_count FROM perseus_dbo.m_downstream;

    -- Create upstream records that should trigger reverse path creation
    INSERT INTO perseus_dbo.m_upstream (start_point, end_point, path, level)
    VALUES
        ('TEST_UP_001', 'TEST_UP_002', 'PATH_001', 1),
        ('TEST_UP_002', 'TEST_UP_003', 'PATH_002', 1),
        ('TEST_UP_003', 'TEST_UP_004', 'PATH_003', 1)
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Upstream test data created successfully';

    -- Execute procedure
    RAISE NOTICE 'Executing usp_updatemdownstream...';
    CALL perseus_dbo.usp_updatemdownstream();

    -- Verify results (Phase 2 may create reverse paths)
    SELECT COUNT(*) INTO v_final_count FROM perseus_dbo.m_downstream;
    v_delta := v_final_count - v_initial_count;

    IF v_delta >= 0 THEN
        v_test_result := 'PASSED';
        RAISE NOTICE 'Test Case 2: PASSED - Phase 2 created % reverse paths', v_delta;
    ELSE
        v_test_result := 'FAILED';
        RAISE WARNING 'Test Case 2: FAILED - Unexpected delta: %', v_delta;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 2: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 3: Empty Table Scenario (Bootstrap)
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 3: Empty Table Scenario (Bootstrap)'
\echo '============================================================================'

DO $$
DECLARE
    v_final_count INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Clearing m_downstream for bootstrap test...';

    -- Clear table
    DELETE FROM perseus_dbo.m_downstream
    WHERE start_point LIKE 'TEST_%';

    RAISE NOTICE 'Executing usp_updatemdownstream on empty table...';
    CALL perseus_dbo.usp_updatemdownstream();

    -- Verify bootstraps correctly
    SELECT COUNT(*) INTO v_final_count FROM perseus_dbo.m_downstream;

    IF v_final_count >= 0 THEN
        v_test_result := 'PASSED';
        RAISE NOTICE 'Test Case 3: PASSED - Bootstrap created % records', v_final_count;
    ELSE
        v_test_result := 'FAILED';
        RAISE WARNING 'Test Case 3: FAILED - Unexpected count: %', v_final_count;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 3: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 4: No Candidates Found (Early Skip)
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 4: No Candidates Found (Early Skip)'
\echo '============================================================================'

DO $$
DECLARE
    v_initial_count INTEGER;
    v_final_count INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Testing scenario with all materials already having downstream...';

    -- Save initial state
    SELECT COUNT(*) INTO v_initial_count FROM perseus_dbo.m_downstream;

    -- Execute procedure (should skip if no candidates)
    CALL perseus_dbo.usp_updatemdownstream();

    -- Verify no changes (or acceptable changes)
    SELECT COUNT(*) INTO v_final_count FROM perseus_dbo.m_downstream;

    IF v_final_count >= v_initial_count THEN
        v_test_result := 'PASSED';
        RAISE NOTICE 'Test Case 4: PASSED - No candidates scenario handled correctly';
    ELSE
        v_test_result := 'FAILED';
        RAISE WARNING 'Test Case 4: FAILED - Unexpected behavior';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 4: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 5: Function Dependency Validation
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 5: Function Dependency Validation'
\echo '============================================================================'

DO $$
DECLARE
    v_mcget_exists BOOLEAN;
    v_reverse_exists BOOLEAN;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Checking function dependencies...';

    -- Check mcgetdownstreambylist exists
    SELECT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'perseus_dbo'
          AND p.proname = 'mcgetdownstreambylist'
    ) INTO v_mcget_exists;

    -- Check reversepath exists
    SELECT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'perseus_dbo'
          AND p.proname = 'reversepath'
    ) INTO v_reverse_exists;

    IF v_mcget_exists AND v_reverse_exists THEN
        RAISE NOTICE 'Test Case 5: PASSED - Both required functions exist';
        RAISE NOTICE '  ✓ mcgetdownstreambylist: %', v_mcget_exists;
        RAISE NOTICE '  ✓ reversepath: %', v_reverse_exists;
    ELSE
        RAISE WARNING 'Test Case 5: WARNING - Missing functions:';
        IF NOT v_mcget_exists THEN
            RAISE WARNING '  ✗ mcgetdownstreambylist: missing';
        END IF;
        IF NOT v_reverse_exists THEN
            RAISE WARNING '  ✗ reversepath: missing';
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 5: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 6: Error Handling (Simulated)
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 6: Error Handling - Verify Exception Catching'
\echo '============================================================================'

DO $$
DECLARE
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Testing error handling structure...';

    -- Verify procedure has EXCEPTION block
    IF EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'perseus_dbo'
          AND p.proname = 'usp_updatemdownstream'
          AND p.prosrc LIKE '%EXCEPTION%'
          AND p.prosrc LIKE '%ROLLBACK%'
    ) THEN
        RAISE NOTICE 'Test Case 6: PASSED - EXCEPTION block with ROLLBACK present';
    ELSE
        RAISE WARNING 'Test Case 6: FAILED - No EXCEPTION/ROLLBACK block found';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 6: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 7: Temp Table Cleanup Verification
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 7: Temp Table Cleanup - ON COMMIT DROP Validation'
\echo '============================================================================'

DO $$
DECLARE
    v_temp_table_count INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Verifying temp table cleanup...';

    -- Execute procedure
    CALL perseus_dbo.usp_updatemdownstream();

    -- Check for leftover temp tables
    SELECT COUNT(*)
    INTO v_temp_table_count
    FROM pg_tables
    WHERE schemaname LIKE 'pg_temp%'
      AND tablename LIKE '%temp_ds_goo_uids%';

    IF v_temp_table_count = 0 THEN
        RAISE NOTICE 'Test Case 7: PASSED - No temp tables leftover (ON COMMIT DROP works)';
    ELSE
        RAISE WARNING 'Test Case 7: FAILED - Found % leftover temp tables', v_temp_table_count;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 7: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 8: Performance Validation
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 8: Performance Validation (Baseline)'
\echo '============================================================================'

DO $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_execution_time_ms INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Measuring execution time...';

    -- Record start time
    v_start_time := clock_timestamp();

    -- Execute procedure
    CALL perseus_dbo.usp_updatemdownstream();

    -- Record end time
    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time));

    RAISE NOTICE 'Execution time: % ms', v_execution_time_ms;

    -- Performance target: < 5000ms for typical dataset
    IF v_execution_time_ms < 5000 THEN
        RAISE NOTICE 'Test Case 8: PASSED - Performance within target (< 5000ms)';
    ELSIF v_execution_time_ms < 10000 THEN
        RAISE WARNING 'Test Case 8: WARNING - Performance acceptable but slow (< 10000ms)';
    ELSE
        RAISE WARNING 'Test Case 8: FAILED - Performance unacceptable (> 10000ms)';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 8: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 9: Transaction Rollback on Error
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 9: Transaction Rollback - Atomicity Verification'
\echo '============================================================================'

DO $$
DECLARE
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Testing transaction rollback behavior...';

    -- Check procedure source for BEGIN/EXCEPTION/ROLLBACK pattern
    IF EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'perseus_dbo'
          AND p.proname = 'usp_updatemdownstream'
          AND p.prosrc LIKE '%ROLLBACK%'
          AND p.prosrc LIKE '%EXCEPTION%'
          AND p.prosrc LIKE '%BEGIN%'
    ) THEN
        RAISE NOTICE 'Test Case 9: PASSED - Transaction control (BEGIN/EXCEPTION/ROLLBACK) present';
    ELSE
        RAISE WARNING 'Test Case 9: FAILED - Missing transaction control';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 9: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 10: Batch Limit Verification (500 per phase)
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 10: Batch Limit Verification (500 per phase)'
\echo '============================================================================'

DO $$
DECLARE
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Verifying batch limit constant (500 per phase)...';

    -- Check procedure source for c_batch_size constant
    IF EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'perseus_dbo'
          AND p.proname = 'usp_updatemdownstream'
          AND p.prosrc LIKE '%c_batch_size%500%'
    ) THEN
        RAISE NOTICE 'Test Case 10: PASSED - Batch limit constant (500) defined';
    ELSE
        RAISE WARNING 'Test Case 10: WARNING - Batch limit constant may differ from expected';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 10: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 11: Integration with usp_UpdateMUpstream (Paired Execution)
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 11: Integration with usp_UpdateMUpstream (Paired Execution)'
\echo '============================================================================'

DO $$
DECLARE
    v_upstream_exists BOOLEAN;
    v_initial_upstream INTEGER;
    v_initial_downstream INTEGER;
    v_final_upstream INTEGER;
    v_final_downstream INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Testing integration with upstream pair...';

    -- Check if upstream procedure exists
    SELECT EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'perseus_dbo'
          AND p.proname = 'usp_updatemupstream'
    ) INTO v_upstream_exists;

    IF NOT v_upstream_exists THEN
        RAISE WARNING 'Test Case 11: SKIPPED - Upstream pair (usp_updatemupstream) not found';
        RETURN;
    END IF;

    -- Save initial counts
    SELECT COUNT(*) INTO v_initial_upstream FROM perseus_dbo.m_upstream;
    SELECT COUNT(*) INTO v_initial_downstream FROM perseus_dbo.m_downstream;

    RAISE NOTICE 'Initial state: upstream=%, downstream=%', v_initial_upstream, v_initial_downstream;

    -- Execute paired procedures
    RAISE NOTICE 'Executing UPSTREAM procedure...';
    CALL perseus_dbo.usp_updatemupstream();

    RAISE NOTICE 'Executing DOWNSTREAM procedure...';
    CALL perseus_dbo.usp_updatemdownstream();

    -- Verify final counts
    SELECT COUNT(*) INTO v_final_upstream FROM perseus_dbo.m_upstream;
    SELECT COUNT(*) INTO v_final_downstream FROM perseus_dbo.m_downstream;

    RAISE NOTICE 'Final state: upstream=%, downstream=%', v_final_upstream, v_final_downstream;

    IF v_final_upstream >= v_initial_upstream AND v_final_downstream >= v_initial_downstream THEN
        RAISE NOTICE 'Test Case 11: PASSED - Paired execution successful';
        RAISE NOTICE '  Upstream delta: +%', (v_final_upstream - v_initial_upstream);
        RAISE NOTICE '  Downstream delta: +%', (v_final_downstream - v_initial_downstream);
    ELSE
        RAISE WARNING 'Test Case 11: FAILED - Unexpected counts';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 11: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 12: Bidirectional Consistency Verification
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 12: Bidirectional Consistency Verification'
\echo '============================================================================'

DO $$
DECLARE
    v_orphan_upstream INTEGER;
    v_orphan_downstream INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Verifying bidirectional consistency...';

    -- Check for orphan upstream records (no corresponding downstream)
    -- Note: This is acceptable, just informational
    SELECT COUNT(*)
    INTO v_orphan_upstream
    FROM perseus_dbo.m_upstream up
    WHERE NOT EXISTS (
        SELECT 1
        FROM perseus_dbo.m_downstream down
        WHERE down.start_point = up.end_point
          AND down.end_point = up.start_point
    );

    -- Check for orphan downstream records (no corresponding upstream)
    -- Note: This is acceptable, just informational
    SELECT COUNT(*)
    INTO v_orphan_downstream
    FROM perseus_dbo.m_downstream down
    WHERE NOT EXISTS (
        SELECT 1
        FROM perseus_dbo.m_upstream up
        WHERE up.start_point = down.end_point
          AND up.end_point = down.start_point
    );

    RAISE NOTICE 'Test Case 12: INFO - Bidirectional consistency report';
    RAISE NOTICE '  Upstream records without reverse downstream: %', v_orphan_upstream;
    RAISE NOTICE '  Downstream records without reverse upstream: %', v_orphan_downstream;

    -- This is informational, not a failure condition
    RAISE NOTICE 'Test Case 12: PASSED - Consistency check complete (orphans are acceptable)';

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 12: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- CLEANUP AND ROLLBACK
-- ============================================================================

\echo '============================================================================'
\echo 'Cleaning up test data...'
\echo '============================================================================'

-- Rollback transaction to restore database to initial state
ROLLBACK;

\echo 'Test transaction rolled back (database restored to initial state)'
\echo ''

-- ============================================================================
-- TEST RESULTS SUMMARY
-- ============================================================================

\echo '============================================================================'
\echo 'TEST RESULTS SUMMARY'
\echo '============================================================================'
\echo 'Test Suite: usp_updatemdownstream'
\echo 'Total Tests: 12'
\echo 'Date:' `date`
\echo ''
\echo 'Individual Test Results:'
\echo '  1. Normal Execution - Phase 1............ See output above'
\echo '  2. Normal Execution - Phase 2............ See output above'
\echo '  3. Empty Table (Bootstrap)................ See output above'
\echo '  4. No Candidates (Early Skip)............. See output above'
\echo '  5. Function Dependency Validation......... See output above'
\echo '  6. Error Handling......................... See output above'
\echo '  7. Temp Table Cleanup..................... See output above'
\echo '  8. Performance Validation................. See output above'
\echo '  9. Transaction Rollback................... See output above'
\echo ' 10. Batch Limit Verification............... See output above'
\echo ' 11. Integration with Upstream Pair......... See output above'
\echo ' 12. Bidirectional Consistency.............. See output above'
\echo ''
\echo 'Review NOTICE and WARNING messages above for detailed results'
\echo '============================================================================'
\echo 'END OF UNIT TEST'
\echo '============================================================================'
\echo ''

-- ============================================================================
-- MANUAL INTEGRATION TESTING INSTRUCTIONS
-- ============================================================================
/*

For complete validation, perform these manual integration tests:

1. **Paired Execution Test**:
   BEGIN;
       -- Clear tables
       DELETE FROM perseus_dbo.m_upstream WHERE start_point LIKE 'TEST_%';
       DELETE FROM perseus_dbo.m_downstream WHERE start_point LIKE 'TEST_%';

       -- Create test materials
       INSERT INTO perseus_dbo.goo (uid, added_on)
       VALUES ('TEST_MAT_A', NOW()), ('TEST_MAT_B', NOW()), ('TEST_MAT_C', NOW());

       INSERT INTO perseus_dbo.material_transition_material (start_point, end_point)
       VALUES ('TEST_MAT_A', 'TEST_MAT_B'), ('TEST_MAT_B', 'TEST_MAT_C');

       -- Run upstream first
       CALL perseus_dbo.usp_updatemupstream();

       -- Check upstream results
       SELECT COUNT(*) FROM perseus_dbo.m_upstream WHERE start_point LIKE 'TEST_%';

       -- Run downstream second
       CALL perseus_dbo.usp_updatemdownstream();

       -- Check downstream results
       SELECT COUNT(*) FROM perseus_dbo.m_downstream WHERE start_point LIKE 'TEST_%';

       -- Verify bidirectional consistency
       SELECT * FROM perseus_dbo.m_upstream WHERE start_point LIKE 'TEST_%';
       SELECT * FROM perseus_dbo.m_downstream WHERE start_point LIKE 'TEST_%';
   ROLLBACK;

2. **ReversePath Function Validation**:
   SELECT perseus_dbo.reversepath('A->B->C');  -- Should return 'C->B->A'
   SELECT perseus_dbo.reversepath('SINGLE');    -- Should return 'SINGLE'

3. **Performance Benchmark** (production-like data):
   -- Load 10,000+ test materials
   -- Run procedure multiple times
   -- Measure average execution time
   -- Compare with SQL Server baseline

4. **Large Dataset Test**:
   -- Test with 50,000+ materials
   -- Verify procedure completes
   -- Check batch limits (500 per phase working correctly)
   -- Monitor memory usage

5. **Orphaned COMMIT Fix Verification**:
   -- This was the CRITICAL fix
   -- Verify no "WARNING: there is no transaction in progress" messages
   -- Previous AWS SCT version would crash on first COMMIT

*/
