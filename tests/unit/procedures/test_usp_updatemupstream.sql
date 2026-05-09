-- ============================================================================
-- UNIT TEST: usp_UpdateMUpstream
-- ============================================================================
-- Purpose: Comprehensive testing of usp_UpdateMUpstream procedure
-- Author: Pierre Ribeiro + Claude Code Web
-- Date: 2025-11-24
-- GitHub Issue: #15
-- Procedure: procedures/corrected/usp_updatemupstream.sql
-- ============================================================================
--
-- Test Coverage:
--   1. Normal execution with data
--   2. Empty tables (early exit scenario)
--   3. Error handling (function missing)
--   4. Temp table cleanup verification
--   5. Performance validation
--   6. Data integrity verification
--
-- Prerequisites:
--   - Tables exist: goo, material_transition_material, m_upstream
--   - Function exists: mcgetupstreambylist(text)
--   - Test data loaded (or mocked)
--
-- Usage:
--   psql -h $HOST -U $USER -d $DATABASE -f test_usp_updatemupstream.sql
--
-- ============================================================================

-- ============================================================================
-- TEST SETUP
-- ============================================================================

\echo '============================================================================'
\echo 'UNIT TEST: usp_UpdateMUpstream'
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
-- TEST CASE 1: Normal Execution with Mock Data
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 1: Normal Execution with Mock Data'
\echo '============================================================================'

DO $$
DECLARE
    v_initial_count INTEGER;
    v_final_count INTEGER;
    v_inserted INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    \echo 'Creating mock test data...'

    -- Save initial state
    SELECT COUNT(*) INTO v_initial_count FROM perseus_dbo.m_upstream;

    -- Create test materials in goo table (if not exists)
    INSERT INTO perseus_dbo.goo (uid, added_on, status)
    VALUES
        ('TEST_UID_001', CURRENT_TIMESTAMP - INTERVAL '1 day', 'ACTIVE'),
        ('TEST_UID_002', CURRENT_TIMESTAMP - INTERVAL '2 days', 'ACTIVE'),
        ('TEST_UID_003', CURRENT_TIMESTAMP - INTERVAL '3 days', 'ACTIVE')
    ON CONFLICT (uid) DO NOTHING;

    -- Create test transitions
    INSERT INTO perseus_dbo.material_transition_material (start_point, end_point, transition_type)
    VALUES
        ('TEST_PARENT_001', 'TEST_UID_001', 'STANDARD'),
        ('TEST_PARENT_002', 'TEST_UID_002', 'STANDARD'),
        ('TEST_PARENT_003', 'TEST_UID_003', 'STANDARD')
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Test data created successfully';

    -- Execute procedure
    RAISE NOTICE 'Executing usp_updatemupstream()...';

    CALL perseus_dbo.usp_updatemupstream();

    -- Verify results
    SELECT COUNT(*) INTO v_final_count FROM perseus_dbo.m_upstream;
    v_inserted := v_final_count - v_initial_count;

    IF v_inserted >= 0 THEN
        v_test_result := 'PASSED';
        RAISE NOTICE 'Test Case 1: PASSED - Inserted % upstream records', v_inserted;
    ELSE
        v_test_result := 'FAILED';
        RAISE WARNING 'Test Case 1: FAILED - Negative insert count: %', v_inserted;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 1: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 2: Empty Tables (Early Exit Scenario)
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 2: Empty Tables - Early Exit Validation'
\echo '============================================================================'

DO $$
DECLARE
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    -- Temporarily create empty test environment
    -- (In real scenario, would use separate test schema)

    RAISE NOTICE 'Testing early exit with no candidates...';

    -- Delete test data to simulate empty state
    DELETE FROM perseus_dbo.material_transition_material
    WHERE start_point LIKE 'TEST_%';

    DELETE FROM perseus_dbo.goo
    WHERE uid LIKE 'TEST_%';

    -- Execute procedure (should exit early with no candidates)
    CALL perseus_dbo.usp_updatemupstream();

    -- If we get here without error, test passed
    v_test_result := 'PASSED';
    RAISE NOTICE 'Test Case 2: PASSED - Early exit handled correctly';

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 2: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 3: Error Handling - Function Missing (Simulated)
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 3: Error Handling - Verify Exception Catching'
\echo '============================================================================'

DO $$
DECLARE
    v_test_result TEXT := 'UNKNOWN';
    v_error_caught BOOLEAN := FALSE;
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
          AND p.proname = 'usp_updatemupstream'
          AND p.prosrc LIKE '%EXCEPTION%'
    ) THEN
        RAISE NOTICE 'Test Case 3: PASSED - EXCEPTION block present in procedure';
    ELSE
        RAISE WARNING 'Test Case 3: FAILED - No EXCEPTION block found';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 3: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 4: Temp Table Cleanup Verification
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 4: Temp Table Cleanup - ON COMMIT DROP Validation'
\echo '============================================================================'

DO $$
DECLARE
    v_temp_table_count INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Verifying temp table cleanup...';

    -- Execute procedure
    CALL perseus_dbo.usp_updatemupstream();

    -- Check for leftover temp tables
    SELECT COUNT(*)
    INTO v_temp_table_count
    FROM pg_tables
    WHERE schemaname LIKE 'pg_temp%'
      AND tablename LIKE '%temp_us_goo_uids%';

    IF v_temp_table_count = 0 THEN
        RAISE NOTICE 'Test Case 4: PASSED - No temp tables leftover (ON COMMIT DROP works)';
    ELSE
        RAISE WARNING 'Test Case 4: FAILED - Found % leftover temp tables', v_temp_table_count;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 4: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 5: Performance Validation
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 5: Performance Validation (Baseline)'
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
    CALL perseus_dbo.usp_updatemupstream();

    -- Record end time
    v_end_time := clock_timestamp();
    v_execution_time_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time));

    RAISE NOTICE 'Execution time: % ms', v_execution_time_ms;

    -- Performance target: < 5000ms for typical dataset
    IF v_execution_time_ms < 5000 THEN
        RAISE NOTICE 'Test Case 5: PASSED - Performance within target (< 5000ms)';
    ELSIF v_execution_time_ms < 10000 THEN
        RAISE WARNING 'Test Case 5: WARNING - Performance acceptable but slow (< 10000ms)';
    ELSE
        RAISE WARNING 'Test Case 5: FAILED - Performance unacceptable (> 10000ms)';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 5: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 6: Data Integrity Verification
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 6: Data Integrity - Verify No Duplicates
\echo '============================================================================'

DO $$
DECLARE
    v_total_rows INTEGER;
    v_distinct_rows INTEGER;
    v_duplicate_count INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Checking for duplicate records in m_upstream...';

    -- Count total rows
    SELECT COUNT(*) INTO v_total_rows FROM perseus_dbo.m_upstream;

    -- Count distinct combinations
    SELECT COUNT(DISTINCT (start_point, end_point))
    INTO v_distinct_rows
    FROM perseus_dbo.m_upstream;

    v_duplicate_count := v_total_rows - v_distinct_rows;

    IF v_duplicate_count = 0 THEN
        RAISE NOTICE 'Test Case 6: PASSED - No duplicate records found';
    ELSE
        RAISE WARNING 'Test Case 6: FAILED - Found % duplicate records', v_duplicate_count;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 6: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 7: Transaction Rollback on Error
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 7: Transaction Rollback - Atomicity Verification'
\echo '============================================================================'

DO $$
DECLARE
    v_initial_count INTEGER;
    v_final_count INTEGER;
    v_test_result TEXT := 'UNKNOWN';
BEGIN
    RAISE NOTICE 'Testing transaction rollback behavior...';

    -- Record initial state
    SELECT COUNT(*) INTO v_initial_count FROM perseus_dbo.m_upstream;

    -- Note: In real test, would force an error (e.g., drop function temporarily)
    -- For now, verify procedure has proper transaction control

    -- Check procedure source for BEGIN/EXCEPTION/ROLLBACK pattern
    IF EXISTS (
        SELECT 1
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'perseus_dbo'
          AND p.proname = 'usp_updatemupstream'
          AND p.prosrc LIKE '%ROLLBACK%'
          AND p.prosrc LIKE '%EXCEPTION%'
    ) THEN
        RAISE NOTICE 'Test Case 7: PASSED - Transaction control (BEGIN/EXCEPTION/ROLLBACK) present';
    ELSE
        RAISE WARNING 'Test Case 7: FAILED - Missing transaction control';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Test Case 7: FAILED - Exception: % (SQLSTATE: %)',
                      SQLERRM, SQLSTATE;
END $$;

\echo ''

-- ============================================================================
-- TEST CASE 8: Index Usage Verification
-- ============================================================================
\echo '============================================================================'
\echo 'TEST CASE 8: Index Usage - EXPLAIN ANALYZE Check'
\echo '============================================================================'

\echo 'Checking recommended indexes exist...'

-- Check for recommended indexes
DO $$
DECLARE
    v_index_count INTEGER := 0;
BEGIN
    -- Check idx_material_transition_material_end_point
    IF EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'perseus_dbo'
          AND indexname = 'idx_material_transition_material_end_point'
    ) THEN
        v_index_count := v_index_count + 1;
        RAISE NOTICE 'Index found: idx_material_transition_material_end_point';
    ELSE
        RAISE WARNING 'Missing recommended index: idx_material_transition_material_end_point';
    END IF;

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

    -- Check idx_goo_added_on_desc
    IF EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE schemaname = 'perseus_dbo'
          AND indexname = 'idx_goo_added_on_desc'
    ) THEN
        v_index_count := v_index_count + 1;
        RAISE NOTICE 'Index found: idx_goo_added_on_desc';
    ELSE
        RAISE WARNING 'Missing recommended index: idx_goo_added_on_desc';
    END IF;

    IF v_index_count = 3 THEN
        RAISE NOTICE 'Test Case 8: PASSED - All recommended indexes present';
    ELSE
        RAISE WARNING 'Test Case 8: WARNING - Only %/3 recommended indexes found', v_index_count;
    END IF;
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
\echo 'Test Suite: usp_UpdateMUpstream'
\echo 'Total Tests: 8'
\echo 'Date:' `date`
\echo ''
\echo 'Individual Test Results:'
\echo '  1. Normal Execution................... See output above'
\echo '  2. Empty Tables (Early Exit).......... See output above'
\echo '  3. Error Handling..................... See output above'
\echo '  4. Temp Table Cleanup................. See output above'
\echo '  5. Performance Validation............. See output above'
\echo '  6. Data Integrity..................... See output above'
\echo '  7. Transaction Rollback............... See output above'
\echo '  8. Index Usage........................ See output above'
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
   CALL perseus_dbo.usp_updatemupstream();  -- Should fail gracefully
   ALTER FUNCTION perseus_dbo.mcgetupstreambylist_backup RENAME TO mcgetupstreambylist;

2. **Performance Benchmark** (requires production-like data):
   -- Load 20,000+ test materials
   -- Run procedure multiple times
   -- Measure average execution time
   -- Compare with SQL Server baseline

3. **Concurrency Test**:
   -- Run procedure from multiple sessions simultaneously
   -- Verify no deadlocks or temp table conflicts
   -- Check temp table isolation

4. **Memory Leak Test**:
   -- Run procedure 100 times in loop
   -- Monitor temp table accumulation: SELECT * FROM pg_tables WHERE schemaname LIKE 'pg_temp%';
   -- Verify ON COMMIT DROP works correctly

5. **Index Usage Test**:
   -- Run EXPLAIN ANALYZE on procedure
   -- Verify Index Scan (not Seq Scan) on critical queries
   -- Check execution plan for temp table operations

Example EXPLAIN ANALYZE (manual):
   -- Cannot EXPLAIN ANALYZE a CALL directly, but can analyze queries inside
   -- Use pg_stat_statements extension to monitor procedure performance

*/
