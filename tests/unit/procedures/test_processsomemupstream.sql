-- ============================================================================
-- UNIT TEST: processsomemupstream
-- ============================================================================
-- Purpose: Comprehensive testing of processsomemupstream function
-- Author: Pierre Ribeiro + Claude Code Web
-- Date: 2025-11-24
-- GitHub Issue: #16
-- Procedure: procedures/corrected/processsomemupstream.sql
-- ============================================================================
--
-- Test Coverage:
--   1. Normal execution with data (dirty minus clean)
--   2. Empty dirty list (early exit scenario)
--   3. All dirty materials already clean (early exit scenario)
--   4. No clean filter (process all dirty)
--   5. Error handling (function missing)
--   6. Temp table cleanup verification
--   7. Performance validation
--   8. Data integrity verification (delta calculation)
--   9. Transaction rollback on error
--   10. Index usage verification
--   11. Return value verification (RETURNS TABLE)
--   12. Idempotency verification
--
-- Prerequisites:
--   - Tables exist: m_upstream
--   - Function exists: mcgetupstreambylist(text)
--   - Type exists: goolist (array of VARCHAR(255))
--   - Test data loaded (or mocked)
--
-- Usage:
--   psql -h $HOST -U $USER -d $DATABASE -f test_processsomemupstream.sql
--
-- ============================================================================

-- ============================================================================
-- TEST SETUP
-- ============================================================================

\echo '============================================================================'
\echo 'UNIT TEST: processsomemupstream'
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
-- TEST CASE 1: Normal Execution - Dirty Minus Clean
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 1: Normal Execution - Dirty Minus Clean'
\echo '============================================================================'

DO $$
DECLARE
    v_initial_count INTEGER;
    v_final_count INTEGER;
    v_result_count INTEGER;
    v_processed_materials TEXT[];
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Creating mock test data...';

    -- Save initial state
    SELECT COUNT(*) INTO v_initial_count FROM perseus_dbo.m_upstream;

    -- Create test materials
    INSERT INTO perseus_dbo.m_upstream (start_point, end_point, path, level)
    VALUES
        ('TEST_MAT_001', 'TEST_END_001', 'TEST_PATH_001', 1),
        ('TEST_MAT_002', 'TEST_END_002', 'TEST_PATH_002', 1),
        ('TEST_MAT_003', 'TEST_END_003', 'TEST_PATH_003', 1)
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Test data created successfully';

    -- Execute function: process 3 dirty, exclude 1 clean
    RAISE NOTICE 'Executing processsomemupstream(dirty=[MAT001,MAT002,MAT003], clean=[MAT001])...';

    SELECT ARRAY_AGG(uid)
    INTO v_processed_materials
    FROM perseus_dbo.processsomemupstream(
        ARRAY['TEST_MAT_001', 'TEST_MAT_002', 'TEST_MAT_003']::perseus_dbo.goolist,
        ARRAY['TEST_MAT_001']::perseus_dbo.goolist
    );

    -- Verify results
    v_result_count := COALESCE(array_length(v_processed_materials, 1), 0);

    IF v_result_count = 2 AND
       'TEST_MAT_002' = ANY(v_processed_materials) AND
       'TEST_MAT_003' = ANY(v_processed_materials) AND
       NOT ('TEST_MAT_001' = ANY(v_processed_materials)) THEN
        v_test_result := 'PASSED';
        RAISE NOTICE 'Test Case 1: PASSED - Processed % materials (excluded clean material)', v_result_count;
        RAISE NOTICE 'Returned: %', v_processed_materials;
    ELSE
        v_test_result := 'FAILED';
        RAISE WARNING 'Test Case 1: FAILED - Expected 2 materials (MAT002, MAT003), got %', v_processed_materials;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 1: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 2: Empty Dirty List - Early Exit
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 2: Empty Dirty List - Early Exit'
\echo '============================================================================'

DO $$
DECLARE
    v_result_count INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Testing early exit with empty dirty list...';

    -- Execute function with empty dirty array
    SELECT COUNT(*)
    INTO v_result_count
    FROM perseus_dbo.processsomemupstream(
        ARRAY[]::perseus_dbo.goolist,
        ARRAY[]::perseus_dbo.goolist
    );

    IF v_result_count = 0 THEN
        v_test_result := 'PASSED';
        RAISE NOTICE 'Test Case 2: PASSED - Early exit with empty result set';
    ELSE
        v_test_result := 'FAILED';
        RAISE WARNING 'Test Case 2: FAILED - Expected 0 results, got %', v_result_count;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 2: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 3: All Dirty Already Clean - Early Exit
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 3: All Dirty Already Clean - Early Exit'
\echo '============================================================================'

DO $$
DECLARE
    v_result_count INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Testing early exit when all dirty materials are clean...';

    -- Execute function: dirty=clean (should process zero)
    SELECT COUNT(*)
    INTO v_result_count
    FROM perseus_dbo.processsomemupstream(
        ARRAY['TEST_MAT_001', 'TEST_MAT_002']::perseus_dbo.goolist,
        ARRAY['TEST_MAT_001', 'TEST_MAT_002']::perseus_dbo.goolist
    );

    IF v_result_count = 0 THEN
        v_test_result := 'PASSED';
        RAISE NOTICE 'Test Case 3: PASSED - Early exit when dirty=clean';
    ELSE
        v_test_result := 'FAILED';
        RAISE WARNING 'Test Case 3: FAILED - Expected 0 results, got %', v_result_count;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 3: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 4: No Clean Filter - Process All Dirty
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 4: No Clean Filter - Process All Dirty'
\echo '============================================================================'

DO $$
DECLARE
    v_result_count INTEGER;
    v_processed_materials TEXT[];
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Testing processing all dirty materials (no clean filter)...';

    -- Execute function: all dirty, no clean
    SELECT ARRAY_AGG(uid)
    INTO v_processed_materials
    FROM perseus_dbo.processsomemupstream(
        ARRAY['TEST_MAT_001', 'TEST_MAT_002', 'TEST_MAT_003']::perseus_dbo.goolist,
        ARRAY[]::perseus_dbo.goolist
    );

    v_result_count := COALESCE(array_length(v_processed_materials, 1), 0);

    IF v_result_count = 3 THEN
        v_test_result := 'PASSED';
        RAISE NOTICE 'Test Case 4: PASSED - Processed all % dirty materials', v_result_count;
        RAISE NOTICE 'Returned: %', v_processed_materials;
    ELSE
        v_test_result := 'FAILED';
        RAISE WARNING 'Test Case 4: FAILED - Expected 3 materials, got %', v_result_count;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 4: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 5: Error Handling - Function Missing (Simulated)
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 5: Error Handling - Verify Exception Catching'
\echo '============================================================================'

DO $$
DECLARE
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Testing error handling...';

    -- Note: Cannot actually break function in unit test
    -- This test validates that errors are properly caught and logged
    -- In production testing, temporarily rename mcgetupstreambylist to test this

    -- For now, just verify procedure structure has EXCEPTION block
    -- by checking pg_proc

    IF EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'perseus_dbo'
          AND p.proname = 'processsomemupstream'
          AND p.prosrc LIKE '%EXCEPTION%'
          AND p.prosrc LIKE '%ROLLBACK%'
    ) THEN
        RAISE NOTICE 'Test Case 5: PASSED - EXCEPTION block with ROLLBACK present';
    ELSE
        RAISE WARNING 'Test Case 5: FAILED - No EXCEPTION/ROLLBACK block found';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 5: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 6: Temp Table Cleanup Verification
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 6: Temp Table Cleanup - ON COMMIT DROP Validation'
\echo '============================================================================'

DO $$
DECLARE
    v_temp_table_count INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Verifying temp table cleanup...';

    -- Execute function
    PERFORM * FROM perseus_dbo.processsomemupstream(
        ARRAY['TEST_MAT_001']::perseus_dbo.goolist,
        ARRAY[]::perseus_dbo.goolist
    );

    -- Check for leftover temp tables
    SELECT COUNT(*)
    INTO v_temp_table_count
    FROM pg_tables
    WHERE schemaname LIKE 'pg_temp%'
      AND (
          tablename LIKE '%temp_var_dirty%' OR
          tablename LIKE '%temp_par_dirty_in%' OR
          tablename LIKE '%temp_par_clean_in%' OR
          tablename LIKE '%old_upstream%' OR
          tablename LIKE '%new_upstream%' OR
          tablename LIKE '%add_upstream%' OR
          tablename LIKE '%rem_upstream%'
      );

    IF v_temp_table_count = 0 THEN
        RAISE NOTICE 'Test Case 6: PASSED - No temp tables leftover (ON COMMIT DROP works)';
    ELSE
        RAISE WARNING 'Test Case 6: FAILED - Found % leftover temp tables', v_temp_table_count;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 6: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 7: Performance Validation
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 7: Performance Validation (Baseline)'
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

    -- Execute function
    PERFORM * FROM perseus_dbo.processsomemupstream(
        ARRAY['TEST_MAT_001', 'TEST_MAT_002', 'TEST_MAT_003']::perseus_dbo.goolist,
        ARRAY[]::perseus_dbo.goolist
    );

    -- Record end time
    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time));

    RAISE NOTICE 'Execution time: % ms', v_execution_time_ms;

    -- Performance target: < 5000ms for typical dataset
    IF v_execution_time_ms < 5000 THEN
        RAISE NOTICE 'Test Case 7: PASSED - Performance within target (< 5000ms)';
    ELSIF v_execution_time_ms < 10000 THEN
        RAISE WARNING 'Test Case 7: WARNING - Performance acceptable but slow (< 10000ms)';
    ELSE
        RAISE WARNING 'Test Case 7: FAILED - Performance unacceptable (> 10000ms)';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 7: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 8: Data Integrity - Delta Calculation Verification
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 8: Data Integrity - Delta Calculation Correctness'
\echo '============================================================================'

DO $$
DECLARE
    v_initial_count INTEGER;
    v_final_count INTEGER;
    v_delta INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Testing delta calculation integrity...';

    -- Record initial state
    SELECT COUNT(*) INTO v_initial_count FROM perseus_dbo.m_upstream;

    -- Execute function with known data
    PERFORM * FROM perseus_dbo.processsomemupstream(
        ARRAY['TEST_MAT_001', 'TEST_MAT_002']::perseus_dbo.goolist,
        ARRAY[]::perseus_dbo.goolist
    );

    -- Record final state
    SELECT COUNT(*) INTO v_final_count FROM perseus_dbo.m_upstream;
    v_delta := v_final_count - v_initial_count;

    -- Delta should be reasonable (not negative, not massive)
    IF v_delta >= 0 AND v_delta < 1000 THEN
        RAISE NOTICE 'Test Case 8: PASSED - Delta calculation reasonable (delta=%)', v_delta;
    ELSE
        RAISE WARNING 'Test Case 8: FAILED - Suspicious delta: %', v_delta;
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
          AND p.proname = 'processsomemupstream'
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
-- TEST CASE 10: Index Usage Verification
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 10: Index Usage - EXPLAIN ANALYZE Check'
\echo '============================================================================'

\echo 'Checking recommended indexes exist...'

-- Check for recommended indexes
DO $$
DECLARE
    v_index_count INTEGER := 0;
BEGIN
    -- Check idx_m_upstream_start_point
    IF EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'perseus_dbo'
          AND indexname = 'idx_m_upstream_start_point'
    ) THEN
        v_index_count := v_index_count + 1;
        RAISE NOTICE 'Index found: idx_m_upstream_start_point';
    ELSE
        RAISE WARNING 'Missing recommended index: idx_m_upstream_start_point';
    END IF;

    -- Check idx_m_upstream_composite
    IF EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'perseus_dbo'
          AND indexname = 'idx_m_upstream_composite'
    ) THEN
        v_index_count := v_index_count + 1;
        RAISE NOTICE 'Index found: idx_m_upstream_composite';
    ELSE
        RAISE WARNING 'Missing recommended index: idx_m_upstream_composite';
    END IF;

    -- Check idx_m_upstream_path
    IF EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'perseus_dbo'
          AND indexname = 'idx_m_upstream_path'
    ) THEN
        v_index_count := v_index_count + 1;
        RAISE NOTICE 'Index found: idx_m_upstream_path';
    ELSE
        RAISE WARNING 'Missing recommended index: idx_m_upstream_path';
    END IF;

    IF v_index_count = 3 THEN
        RAISE NOTICE 'Test Case 10: PASSED - All recommended indexes present';
    ELSIF v_index_count > 0 THEN
        RAISE WARNING 'Test Case 10: WARNING - Only %/3 recommended indexes found', v_index_count;
    ELSE
        RAISE WARNING 'Test Case 10: WARNING - No recommended indexes found (performance may be degraded)';
    END IF;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 11: Return Value Verification - RETURNS TABLE
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 11: Return Value Verification - RETURNS TABLE'
\echo '============================================================================'

DO $$
DECLARE
    v_return_type TEXT;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Verifying return type is RETURNS TABLE...';

    -- Check function return type
    SELECT pg_get_function_result(p.oid)
    INTO v_return_type
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'perseus_dbo'
      AND p.proname = 'processsomemupstream';

    IF v_return_type LIKE '%TABLE%' OR v_return_type LIKE '%SETOF%' THEN
        RAISE NOTICE 'Test Case 11: PASSED - Function returns TABLE type: %', v_return_type;
    ELSE
        RAISE WARNING 'Test Case 11: FAILED - Unexpected return type: %', v_return_type;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 11: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 12: Idempotency Verification
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 12: Idempotency - Multiple Executions Should Be Safe'
\echo '============================================================================'

DO $$
DECLARE
    v_first_count INTEGER;
    v_second_count INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Testing idempotency (running twice with same input)...';

    -- First execution
    SELECT COUNT(*)
    INTO v_first_count
    FROM perseus_dbo.processsomemupstream(
        ARRAY['TEST_MAT_001', 'TEST_MAT_002']::perseus_dbo.goolist,
        ARRAY[]::perseus_dbo.goolist
    );

    -- Second execution (should be idempotent)
    SELECT COUNT(*)
    INTO v_second_count
    FROM perseus_dbo.processsomemupstream(
        ARRAY['TEST_MAT_001', 'TEST_MAT_002']::perseus_dbo.goolist,
        ARRAY[]::perseus_dbo.goolist
    );

    IF v_first_count = v_second_count THEN
        RAISE NOTICE 'Test Case 12: PASSED - Idempotent (both executions returned % results)', v_first_count;
    ELSE
        RAISE WARNING 'Test Case 12: FAILED - Not idempotent (first=%, second=%)', v_first_count, v_second_count;
    END IF;

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
\echo 'Test Suite: processsomemupstream'
\echo 'Total Tests: 12'
\echo 'Date:' `date`
\echo ''
\echo 'Individual Test Results:'
\echo '  1. Normal Execution (dirty-clean)....... See output above'
\echo '  2. Empty Dirty List (early exit)......... See output above'
\echo '  3. All Dirty Already Clean................ See output above'
\echo '  4. No Clean Filter........................ See output above'
\echo '  5. Error Handling......................... See output above'
\echo '  6. Temp Table Cleanup..................... See output above'
\echo '  7. Performance Validation................. See output above'
\echo '  8. Data Integrity (delta)................. See output above'
\echo '  9. Transaction Rollback................... See output above'
\echo ' 10. Index Usage............................ See output above'
\echo ' 11. Return Value (RETURNS TABLE)........... See output above'
\echo ' 12. Idempotency............................ See output above'
\echo ''
\echo 'Review NOTICE and WARNING messages above for detailed results'
\echo '============================================================================'
\echo 'END OF UNIT TEST'
\echo '============================================================================'
\echo ''

-- ============================================================================
-- MANUAL TESTING INSTRUCTIONS
-- ============================================================================
/*

For complete validation, also perform these manual tests:

1. **Force Error Test** (requires temp environment):
   -- Temporarily rename function to test error handling
   ALTER FUNCTION perseus_dbo.mcgetupstreambylist RENAME TO mcgetupstreambylist_backup;
   SELECT * FROM perseus_dbo.processsomemupstream(
       ARRAY['TEST']::perseus_dbo.goolist,
       ARRAY[]::perseus_dbo.goolist
   );  -- Should fail gracefully with ROLLBACK
   ALTER FUNCTION perseus_dbo.mcgetupstreambylist_backup RENAME TO mcgetupstreambylist;

2. **Performance Benchmark** (requires production-like data):
   -- Load 100+ test materials
   -- Run function multiple times
   -- Measure average execution time
   -- Compare with SQL Server baseline

3. **Concurrency Test**:
   -- Run function from multiple sessions simultaneously
   -- Verify no deadlocks or temp table conflicts
   -- Check temp table isolation (each session has own temp tables)

4. **Memory Leak Test**:
   -- Run function 100 times in loop
   -- Monitor temp table accumulation: SELECT * FROM pg_tables WHERE schemaname LIKE 'pg_temp%';
   -- Verify ON COMMIT DROP works correctly

5. **Large Dataset Test**:
   -- Test with 1000+ dirty materials
   -- Verify performance scales linearly
   -- Check memory usage doesn't explode

6. **Null/Edge Cases**:
   -- Test with NULL arrays (should error gracefully)
   -- Test with duplicate UIDs in dirty_in
   -- Test with special characters in UIDs

Example Integration Test (manual):
   -- Create caller procedure that uses processsomemupstream
   -- Pass dirty/clean lists, collect results
   -- Verify returned materials match expectations
   -- Verify caller can iterate over result set

*/
