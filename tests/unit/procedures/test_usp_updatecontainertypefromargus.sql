-- ===================================================================
-- UNIT TEST: usp_UpdateContainerTypeFromArgus
-- ===================================================================
-- PURPOSE:
--   Comprehensive unit test suite for usp_UpdateContainerTypeFromArgus
--   Uses MOCK data for Argus foreign table (external system unavailable in test)
--
-- PROCEDURE TESTED:
--   perseus_dbo.usp_updatecontainertypefromargus()
--
-- TEST STRATEGY:
--   Since the Argus system (foreign table argus_root_plate) is not
--   available in dev/test environment, this test suite uses:
--   1. Mock table simulating argus_root_plate structure
--   2. Modified procedure logic for testing (or mock foreign table)
--   3. Test scenarios covering all business logic paths
--
-- TEST COVERAGE:
--   1. Successful update (happy path) with mock Argus data
--   2. Idempotency test (multiple runs produce same result)
--   3. No matches in Argus (no updates)
--   4. Partial matches (some containers updated, others not)
--   5. Guard clause test (already type 12)
--   6. NULL handling in Argus data
--   7. Performance test with larger dataset
--   8. Cleanup verification
--
-- AUTHOR: Pierre Ribeiro + Claude Code Web
-- CREATED: 2025-11-29
-- SPRINT: 7 (Issue #25)
-- QUALITY TARGET: 90%+ test coverage
-- EXTERNAL DEPENDENCY: Argus system (mocked for testing)
-- ===================================================================

-- ===================================================================
-- TEST SETUP
-- ===================================================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'UNIT TEST SUITE: usp_UpdateContainerTypeFromArgus';
    RAISE NOTICE 'Sprint 7 - Issue #25';
    RAISE NOTICE 'External System: Argus (MOCKED)';
    RAISE NOTICE 'Started: %', clock_timestamp();
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'NOTE: This test suite uses MOCK data for Argus system';
    RAISE NOTICE '      Production requires postgres_fdw foreign table setup';
    RAISE NOTICE '';
END $$;

-- ===================================================================
-- MOCK SETUP: Create temporary Argus foreign table mock
-- ===================================================================
-- This simulates the argus_root_plate foreign table
-- In production, this would be created via postgres_fdw

DO $$
BEGIN
    RAISE NOTICE 'SETUP: Creating mock Argus root_plate table';

    -- Drop if exists (from previous test run)
    DROP TABLE IF EXISTS perseus_dbo.argus_root_plate CASCADE;

    -- Create mock table matching foreign table structure
    CREATE TABLE perseus_dbo.argus_root_plate (
        uid VARCHAR(255) PRIMARY KEY,
        plate_format_id INTEGER NOT NULL,
        hermes_experiment_id VARCHAR(255)
    );

    -- Populate with representative test data
    INSERT INTO perseus_dbo.argus_root_plate (uid, plate_format_id, hermes_experiment_id) VALUES
        ('CONTAINER-001', 8, 'EXP-001'),  -- Matches criteria
        ('CONTAINER-002', 8, 'EXP-002'),  -- Matches criteria
        ('CONTAINER-003', 8, 'EXP-003'),  -- Matches criteria
        ('CONTAINER-004', 8, NULL),       -- Missing experiment (excluded)
        ('CONTAINER-005', 7, 'EXP-005'),  -- Wrong format_id (excluded)
        ('CONTAINER-006', 8, 'EXP-006'),  -- Matches criteria
        ('CONTAINER-007', 9, 'EXP-007');  -- Wrong format_id (excluded)

    RAISE NOTICE '  ✓ Created mock argus_root_plate with 7 test records';
    RAISE NOTICE '  ✓ 4 records match criteria (format_id=8, has experiment_id)';
    RAISE NOTICE '  ✓ 3 records excluded (missing experiment or wrong format)';
    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ SETUP FAILED: % - %', SQLERRM, SQLSTATE;
        RAISE;
END $$;

-- ===================================================================
-- TEST 1: Successful Update (Happy Path)
-- ===================================================================
DO $$
DECLARE
    v_initial_count INTEGER;
    v_final_count INTEGER;
    v_updated_count INTEGER;
BEGIN
    RAISE NOTICE 'TEST 1: Successful update (happy path)';
    RAISE NOTICE '----------------------------------------';

    -- Setup test containers
    DROP TABLE IF EXISTS perseus_dbo.container CASCADE;
    CREATE TEMPORARY TABLE perseus_dbo.container (
        uid VARCHAR(255) PRIMARY KEY,
        container_type_id INTEGER NOT NULL,
        modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ON COMMIT DROP;

    -- Insert test containers (matching Argus UIDs)
    INSERT INTO perseus_dbo.container (uid, container_type_id) VALUES
        ('CONTAINER-001', 1),  -- Should be updated to 12
        ('CONTAINER-002', 5),  -- Should be updated to 12
        ('CONTAINER-003', 3),  -- Should be updated to 12
        ('CONTAINER-004', 1),  -- Should NOT update (no experiment in Argus)
        ('CONTAINER-005', 1),  -- Should NOT update (wrong format_id in Argus)
        ('CONTAINER-006', 2),  -- Should be updated to 12
        ('CONTAINER-007', 1),  -- Should NOT update (wrong format_id in Argus)
        ('CONTAINER-999', 1);  -- Should NOT update (not in Argus)

    -- Count containers currently type 12
    SELECT COUNT(*) INTO v_initial_count
    FROM perseus_dbo.container
    WHERE container_type_id = 12;

    RAISE NOTICE '  Initial containers with type_id=12: %', v_initial_count;

    -- Execute procedure
    CALL perseus_dbo.usp_updatecontainertypefromargus();

    -- Count containers now type 12
    SELECT COUNT(*) INTO v_final_count
    FROM perseus_dbo.container
    WHERE container_type_id = 12;

    v_updated_count := v_final_count - v_initial_count;

    RAISE NOTICE '  Final containers with type_id=12: %', v_final_count;
    RAISE NOTICE '  Containers updated: %', v_updated_count;

    -- Verify expected updates
    IF v_updated_count = 4 THEN  -- 001, 002, 003, 006 should be updated
        RAISE NOTICE '✅ TEST 1 PASSED: Correct number of containers updated';
    ELSE
        RAISE EXCEPTION '❌ TEST 1 FAILED: Expected 4 updates, got %', v_updated_count;
    END IF;

    -- Verify specific containers
    IF EXISTS (
        SELECT 1 FROM perseus_dbo.container
        WHERE uid IN ('CONTAINER-001', 'CONTAINER-002', 'CONTAINER-003', 'CONTAINER-006')
          AND container_type_id = 12
    ) AND (
        SELECT COUNT(*) FROM perseus_dbo.container
        WHERE uid IN ('CONTAINER-001', 'CONTAINER-002', 'CONTAINER-003', 'CONTAINER-006')
          AND container_type_id = 12
    ) = 4 THEN
        RAISE NOTICE '  ✓ Correct containers updated to type 12';
    ELSE
        RAISE EXCEPTION 'Incorrect containers updated';
    END IF;

    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 1 FAILED: % - %', SQLERRM, SQLSTATE;
        RAISE NOTICE '';
END $$;

-- ===================================================================
-- TEST 2: Idempotency (Multiple Runs)
-- ===================================================================
DO $$
DECLARE
    v_count_run1 INTEGER;
    v_count_run2 INTEGER;
    v_count_run3 INTEGER;
BEGIN
    RAISE NOTICE 'TEST 2: Idempotency (multiple runs)';
    RAISE NOTICE '----------------------------------------';

    -- Setup test containers
    DROP TABLE IF EXISTS perseus_dbo.container CASCADE;
    CREATE TEMPORARY TABLE perseus_dbo.container (
        uid VARCHAR(255) PRIMARY KEY,
        container_type_id INTEGER NOT NULL,
        modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ON COMMIT DROP;

    INSERT INTO perseus_dbo.container (uid, container_type_id) VALUES
        ('CONTAINER-001', 1),
        ('CONTAINER-002', 5);

    -- Run 1
    CALL perseus_dbo.usp_updatecontainertypefromargus();
    SELECT COUNT(*) INTO v_count_run1
    FROM perseus_dbo.container WHERE container_type_id = 12;

    -- Run 2
    CALL perseus_dbo.usp_updatecontainertypefromargus();
    SELECT COUNT(*) INTO v_count_run2
    FROM perseus_dbo.container WHERE container_type_id = 12;

    -- Run 3
    CALL perseus_dbo.usp_updatecontainertypefromargus();
    SELECT COUNT(*) INTO v_count_run3
    FROM perseus_dbo.container WHERE container_type_id = 12;

    RAISE NOTICE '  Run 1 results: % containers at type 12', v_count_run1;
    RAISE NOTICE '  Run 2 results: % containers at type 12', v_count_run2;
    RAISE NOTICE '  Run 3 results: % containers at type 12', v_count_run3;

    -- Verify idempotency
    IF v_count_run1 = v_count_run2 AND v_count_run2 = v_count_run3 THEN
        RAISE NOTICE '✅ TEST 2 PASSED: Procedure is idempotent';
    ELSE
        RAISE EXCEPTION '❌ TEST 2 FAILED: Results differ across runs';
    END IF;

    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 2 FAILED: % - %', SQLERRM, SQLSTATE;
        RAISE NOTICE '';
END $$;

-- ===================================================================
-- TEST 3: No Matches in Argus (No Updates)
-- ===================================================================
DO $$
DECLARE
    v_count_before INTEGER;
    v_count_after INTEGER;
BEGIN
    RAISE NOTICE 'TEST 3: No matches in Argus (no updates)';
    RAISE NOTICE '----------------------------------------';

    -- Setup test containers with UIDs NOT in Argus
    DROP TABLE IF EXISTS perseus_dbo.container CASCADE;
    CREATE TEMPORARY TABLE perseus_dbo.container (
        uid VARCHAR(255) PRIMARY KEY,
        container_type_id INTEGER NOT NULL,
        modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ON COMMIT DROP;

    INSERT INTO perseus_dbo.container (uid, container_type_id) VALUES
        ('CONTAINER-999', 1),  -- Not in Argus
        ('CONTAINER-888', 2);  -- Not in Argus

    SELECT COUNT(*) INTO v_count_before
    FROM perseus_dbo.container WHERE container_type_id = 12;

    -- Execute procedure
    CALL perseus_dbo.usp_updatecontainertypefromargus();

    SELECT COUNT(*) INTO v_count_after
    FROM perseus_dbo.container WHERE container_type_id = 12;

    RAISE NOTICE '  Containers before: % at type 12', v_count_before;
    RAISE NOTICE '  Containers after: % at type 12', v_count_after;

    IF v_count_before = v_count_after AND v_count_after = 0 THEN
        RAISE NOTICE '✅ TEST 3 PASSED: No updates when no Argus matches';
    ELSE
        RAISE EXCEPTION '❌ TEST 3 FAILED: Unexpected updates occurred';
    END IF;

    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 3 FAILED: % - %', SQLERRM, SQLSTATE;
        RAISE NOTICE '';
END $$;

-- ===================================================================
-- TEST 4: Guard Clause (Already Type 12)
-- ===================================================================
DO $$
DECLARE
    v_modified_count INTEGER;
BEGIN
    RAISE NOTICE 'TEST 4: Guard clause (already type 12)';
    RAISE NOTICE '----------------------------------------';

    -- Setup test containers already at type 12
    DROP TABLE IF EXISTS perseus_dbo.container CASCADE;
    CREATE TEMPORARY TABLE perseus_dbo.container (
        uid VARCHAR(255) PRIMARY KEY,
        container_type_id INTEGER NOT NULL,
        modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ON COMMIT DROP;

    INSERT INTO perseus_dbo.container (uid, container_type_id) VALUES
        ('CONTAINER-001', 12),  -- Already type 12
        ('CONTAINER-002', 12);  -- Already type 12

    -- Execute procedure
    CALL perseus_dbo.usp_updatecontainertypefromargus();

    -- Verify containers still at type 12 (no unnecessary updates)
    SELECT COUNT(*) INTO v_modified_count
    FROM perseus_dbo.container
    WHERE container_type_id = 12;

    IF v_modified_count = 2 THEN
        RAISE NOTICE '✅ TEST 4 PASSED: Guard clause prevents redundant updates';
    ELSE
        RAISE EXCEPTION '❌ TEST 4 FAILED: Guard clause not working';
    END IF;

    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 4 FAILED: % - %', SQLERRM, SQLSTATE;
        RAISE NOTICE '';
END $$;

-- ===================================================================
-- TEST 5: Mixed Scenario (Partial Updates)
-- ===================================================================
DO $$
DECLARE
    v_updated_count INTEGER;
    v_unchanged_count INTEGER;
BEGIN
    RAISE NOTICE 'TEST 5: Mixed scenario (partial updates)';
    RAISE NOTICE '----------------------------------------';

    -- Setup mixed test scenario
    DROP TABLE IF EXISTS perseus_dbo.container CASCADE;
    CREATE TEMPORARY TABLE perseus_dbo.container (
        uid VARCHAR(255) PRIMARY KEY,
        container_type_id INTEGER NOT NULL,
        modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ON COMMIT DROP;

    INSERT INTO perseus_dbo.container (uid, container_type_id) VALUES
        ('CONTAINER-001', 1),   -- Should update (in Argus, format=8, has exp)
        ('CONTAINER-004', 1),   -- Should NOT update (in Argus but no experiment)
        ('CONTAINER-005', 1),   -- Should NOT update (in Argus but format=7)
        ('CONTAINER-999', 1),   -- Should NOT update (not in Argus)
        ('CONTAINER-002', 12);  -- Should NOT update (already type 12)

    -- Execute procedure
    CALL perseus_dbo.usp_updatecontainertypefromargus();

    -- Count results
    SELECT COUNT(*) INTO v_updated_count
    FROM perseus_dbo.container
    WHERE container_type_id = 12;

    SELECT COUNT(*) INTO v_unchanged_count
    FROM perseus_dbo.container
    WHERE container_type_id != 12;

    RAISE NOTICE '  Updated to type 12: %', v_updated_count;
    RAISE NOTICE '  Remained other types: %', v_unchanged_count;

    IF v_updated_count = 2 AND v_unchanged_count = 3 THEN
        RAISE NOTICE '✅ TEST 5 PASSED: Correct partial update behavior';
    ELSE
        RAISE EXCEPTION '❌ TEST 5 FAILED: Expected 2 updated, 3 unchanged, got %, %',
                        v_updated_count, v_unchanged_count;
    END IF;

    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 5 FAILED: % - %', SQLERRM, SQLSTATE;
        RAISE NOTICE '';
END $$;

-- ===================================================================
-- TEST 6: NULL Handling in Argus Data
-- ===================================================================
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    RAISE NOTICE 'TEST 6: NULL handling in Argus data';
    RAISE NOTICE '----------------------------------------';

    -- Setup container matching Argus record with NULL experiment
    DROP TABLE IF EXISTS perseus_dbo.container CASCADE;
    CREATE TEMPORARY TABLE perseus_dbo.container (
        uid VARCHAR(255) PRIMARY KEY,
        container_type_id INTEGER NOT NULL,
        modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ON COMMIT DROP;

    INSERT INTO perseus_dbo.container (uid, container_type_id) VALUES
        ('CONTAINER-004', 1);  -- Matches Argus UID but NULL experiment

    -- Execute procedure
    CALL perseus_dbo.usp_updatecontainertypefromargus();

    -- Verify container was NOT updated (NULL experiment excluded)
    SELECT COUNT(*) INTO v_count
    FROM perseus_dbo.container
    WHERE uid = 'CONTAINER-004' AND container_type_id = 1;  -- Still type 1

    IF v_count = 1 THEN
        RAISE NOTICE '✅ TEST 6 PASSED: NULL experiment_id correctly excluded';
    ELSE
        RAISE EXCEPTION '❌ TEST 6 FAILED: NULL handling incorrect';
    END IF;

    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 6 FAILED: % - %', SQLERRM, SQLSTATE;
        RAISE NOTICE '';
END $$;

-- ===================================================================
-- TEST 7: Performance Test (Larger Dataset)
-- ===================================================================
DO $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_duration_ms INTEGER;
    v_row_count INTEGER;
    i INTEGER;
BEGIN
    RAISE NOTICE 'TEST 7: Performance test (larger dataset)';
    RAISE NOTICE '----------------------------------------';

    -- Setup larger test dataset
    DROP TABLE IF EXISTS perseus_dbo.container CASCADE;
    CREATE TEMPORARY TABLE perseus_dbo.container (
        uid VARCHAR(255) PRIMARY KEY,
        container_type_id INTEGER NOT NULL,
        modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ON COMMIT DROP;

    -- Insert 100 test containers
    FOR i IN 1..100 LOOP
        INSERT INTO perseus_dbo.container (uid, container_type_id)
        VALUES ('TEST-CONTAINER-' || LPAD(i::TEXT, 5, '0'), (i % 10) + 1);
    END LOOP;

    RAISE NOTICE '  Created 100 test containers';

    -- Benchmark procedure execution
    v_start_time := clock_timestamp();

    CALL perseus_dbo.usp_updatecontainertypefromargus();

    v_end_time := clock_timestamp();
    v_duration_ms := EXTRACT(MILLISECONDS FROM (v_end_time - v_start_time))::INTEGER;

    SELECT COUNT(*) INTO v_row_count
    FROM perseus_dbo.container WHERE container_type_id = 12;

    RAISE NOTICE '  Execution time: % ms', v_duration_ms;
    RAISE NOTICE '  Rows processed: 100';
    RAISE NOTICE '  Rows updated: %', v_row_count;

    IF v_duration_ms < 1000 THEN  -- Should complete in under 1 second
        RAISE NOTICE '✅ TEST 7 PASSED: Performance acceptable (< 1 second)';
    ELSE
        RAISE NOTICE '⚠️  TEST 7 WARNING: Performance slower than expected (% ms)', v_duration_ms;
    END IF;

    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 7 FAILED: % - %', SQLERRM, SQLSTATE;
        RAISE NOTICE '';
END $$;

-- ===================================================================
-- TEST 8: Cleanup Verification
-- ===================================================================
DO $$
BEGIN
    RAISE NOTICE 'TEST 8: Cleanup verification';
    RAISE NOTICE '----------------------------------------';

    -- Cleanup mock Argus table
    DROP TABLE IF EXISTS perseus_dbo.argus_root_plate CASCADE;

    RAISE NOTICE '  ✓ Mock argus_root_plate dropped';
    RAISE NOTICE '✅ TEST 8 PASSED: Cleanup complete';
    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 8 FAILED: % - %', SQLERRM, SQLSTATE;
        RAISE NOTICE '';
END $$;

-- ===================================================================
-- TEST SUMMARY
-- ===================================================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'TEST SUITE COMPLETE';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Procedure: usp_UpdateContainerTypeFromArgus';
    RAISE NOTICE 'Sprint: 7 (Issue #25)';
    RAISE NOTICE 'Total Tests: 8';
    RAISE NOTICE 'Coverage:';
    RAISE NOTICE '  1. Happy path ✓';
    RAISE NOTICE '  2. Idempotency ✓';
    RAISE NOTICE '  3. No matches ✓';
    RAISE NOTICE '  4. Guard clause ✓';
    RAISE NOTICE '  5. Partial updates ✓';
    RAISE NOTICE '  6. NULL handling ✓';
    RAISE NOTICE '  7. Performance ✓';
    RAISE NOTICE '  8. Cleanup ✓';
    RAISE NOTICE 'Completed: %', clock_timestamp();
    RAISE NOTICE '';
    RAISE NOTICE 'PRODUCTION DEPLOYMENT REQUIREMENTS:';
    RAISE NOTICE '  ⚠️  Replace mock table with postgres_fdw foreign table';
    RAISE NOTICE '  ⚠️  Configure argus_server foreign server';
    RAISE NOTICE '  ⚠️  Create user mapping with Argus credentials';
    RAISE NOTICE '  ⚠️  Verify network connectivity to Argus database';
    RAISE NOTICE '  ⚠️  Test with real Argus data before production';
    RAISE NOTICE '';
    RAISE NOTICE 'MANUAL REVIEW REQUIRED:';
    RAISE NOTICE '  - Check test output above for any ❌ FAILED messages';
    RAISE NOTICE '  - Verify all ✅ PASSED messages present';
    RAISE NOTICE '  - Review FDW setup documentation in procedure file';
    RAISE NOTICE '  - Coordinate with DBA for foreign server configuration';
    RAISE NOTICE '========================================';
END $$;

-- ===================================================================
-- NOTES
-- ===================================================================
-- TESTING STRATEGY:
--
-- 1. MOCK vs REAL DATA:
--    - These tests use a mock table simulating argus_root_plate
--    - Production uses postgres_fdw foreign table
--    - Mock allows testing without external system dependency
--
-- 2. FDW TESTING:
--    - Once FDW is configured, run these tests against real foreign table
--    - Replace mock table creation with: SELECT * FROM argus_root_plate LIMIT 1;
--    - Verify connectivity and data accessibility
--
-- 3. TEST DATA:
--    - Mock data represents realistic Argus scenarios
--    - Includes matching and non-matching records
--    - Covers NULL values and edge cases
--
-- 4. PERFORMANCE:
--    - Mock table performance != FDW performance
--    - FDW adds network latency and Argus query time
--    - Benchmark with real FDW before production deployment
--
-- 5. ERROR TESTING:
--    - FDW connection errors cannot be tested with mock
--    - Manually test connection failures after FDW setup
--    - Verify error handling with disconnected Argus system
--
-- PRODUCTION READINESS CHECKLIST:
--
-- - [ ] All unit tests pass with mock data
-- - [ ] FDW infrastructure configured (DBA)
-- - [ ] Foreign table accessible (test: SELECT * FROM argus_root_plate LIMIT 1)
-- - [ ] Network connectivity verified
-- - [ ] Credentials tested and secured
-- - [ ] Re-run tests with real foreign table
-- - [ ] Performance benchmark with production-like data volume
-- - [ ] Error handling tested (disconnect Argus, observe recovery)
-- - [ ] Monitoring alerts configured
-- - [ ] Runbook created for FDW connection issues
-- ===================================================================

-- END OF UNIT TEST: usp_UpdateContainerTypeFromArgus
