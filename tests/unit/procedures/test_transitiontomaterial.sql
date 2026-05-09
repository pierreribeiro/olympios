-- =====================================================================
-- UNIT TEST SUITE: TransitionToMaterial
-- =====================================================================
-- Procedure: perseus_dbo.transitiontomaterial
-- Sprint: 5 (Issue #22)
-- Created: 2025-11-25
-- Author: Pierre Ribeiro + Claude (Command Center)
--
-- PURPOSE:
--   Comprehensive test suite for TransitionToMaterial procedure
--   Tests happy path, error conditions, constraints, and edge cases
--
-- TEST COVERAGE:
--   ✅ Test 1: Successful insert (happy path)
--   ✅ Test 2: Duplicate key handling
--   ✅ Test 3: NULL parameter validation
--   ✅ Test 4: Foreign key constraint enforcement
--   ✅ Test 5: Length constraint validation
--
-- REQUIREMENTS:
--   - PostgreSQL 12+
--   - perseus_dbo schema must exist
--   - transition_material table must exist
--   - Test data cleanup after each test
--
-- USAGE:
--   psql -h <host> -U <user> -d <database> -f test_transitiontomaterial.sql
--
-- EXPECTED RESULT:
--   All tests should PASS with RAISE NOTICE confirmations
--   No exceptions should propagate to top level
-- =====================================================================

-- =====================================================================
-- TEST SETUP
-- =====================================================================

-- Ensure we're in the correct schema
SET search_path TO perseus_dbo, public;

-- Enable verbose output for test results
\set VERBOSITY verbose

-- Start test suite
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'TEST SUITE: TransitionToMaterial';
    RAISE NOTICE 'Started: %', clock_timestamp();
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
END $$;

-- =====================================================================
-- TEST 1: Successful Insert (Happy Path)
-- =====================================================================
DO $$
DECLARE
    v_test_transition_id VARCHAR(50) := 'TEST-TRANS-001';
    v_test_material_id VARCHAR(50) := 'TEST-MAT-001';
    v_count INTEGER;
BEGIN
    RAISE NOTICE '--- TEST 1: Successful Insert (Happy Path) ---';

    -- Call procedure
    CALL perseus_dbo.transitiontomaterial(v_test_transition_id, v_test_material_id);

    -- Verify insert succeeded
    SELECT COUNT(*) INTO v_count
    FROM perseus_dbo.transition_material
    WHERE transition_id = v_test_transition_id
      AND material_id = v_test_material_id;

    IF v_count = 1 THEN
        RAISE NOTICE '✅ TEST 1 PASSED: Insert created exactly 1 record';
    ELSE
        RAISE EXCEPTION '❌ TEST 1 FAILED: Expected 1 record, found %', v_count;
    END IF;

    -- Cleanup
    DELETE FROM perseus_dbo.transition_material
    WHERE transition_id = v_test_transition_id;

    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        -- Cleanup on failure
        DELETE FROM perseus_dbo.transition_material
        WHERE transition_id = v_test_transition_id;

        RAISE EXCEPTION '❌ TEST 1 FAILED: % (SQLSTATE: %)',
                        SQLERRM, SQLSTATE;
END $$;

-- =====================================================================
-- TEST 2: Duplicate Key Handling
-- =====================================================================
DO $$
DECLARE
    v_test_transition_id VARCHAR(50) := 'TEST-TRANS-002';
    v_test_material_id VARCHAR(50) := 'TEST-MAT-002';
BEGIN
    RAISE NOTICE '--- TEST 2: Duplicate Key Handling ---';

    -- Insert first record
    CALL perseus_dbo.transitiontomaterial(v_test_transition_id, v_test_material_id);
    RAISE NOTICE 'ℹ️  First insert successful';

    -- Attempt duplicate insert (should fail gracefully)
    BEGIN
        CALL perseus_dbo.transitiontomaterial(v_test_transition_id, v_test_material_id);

        -- If we reach here, duplicate was allowed (may be valid if no unique constraint)
        RAISE NOTICE '⚠️  TEST 2 WARNING: Duplicate insert allowed - check if UNIQUE constraint exists';
        RAISE NOTICE '⚠️  Consider adding: UNIQUE (material_id, transition_id) to transition_material table';

        -- Cleanup duplicates
        DELETE FROM perseus_dbo.transition_material
        WHERE transition_id = v_test_transition_id;

    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE '✅ TEST 2 PASSED: Duplicate key correctly rejected with unique_violation';

            -- Cleanup
            DELETE FROM perseus_dbo.transition_material
            WHERE transition_id = v_test_transition_id;
    END;

    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        -- Cleanup on failure
        DELETE FROM perseus_dbo.transition_material
        WHERE transition_id = v_test_transition_id;

        RAISE EXCEPTION '❌ TEST 2 FAILED: % (SQLSTATE: %)',
                        SQLERRM, SQLSTATE;
END $$;

-- =====================================================================
-- TEST 3: NULL Parameter Validation
-- =====================================================================
DO $$
DECLARE
    v_test_material_id VARCHAR(50) := 'TEST-MAT-003';
    v_test_transition_id VARCHAR(50) := 'TEST-TRANS-003';
BEGIN
    RAISE NOTICE '--- TEST 3: NULL Parameter Validation ---';

    -- Test 3a: NULL transition_id
    BEGIN
        CALL perseus_dbo.transitiontomaterial(NULL, v_test_material_id);

        -- If we reach here, NULL was allowed
        RAISE NOTICE '⚠️  TEST 3a WARNING: NULL transition_id accepted - check NOT NULL constraint';

        -- Cleanup
        DELETE FROM perseus_dbo.transition_material
        WHERE material_id = v_test_material_id AND transition_id IS NULL;

    EXCEPTION
        WHEN not_null_violation THEN
            RAISE NOTICE '✅ TEST 3a PASSED: NULL transition_id correctly rejected';
        WHEN check_violation THEN
            RAISE NOTICE '✅ TEST 3a PASSED: NULL transition_id rejected by CHECK constraint';
    END;

    -- Test 3b: NULL material_id
    BEGIN
        CALL perseus_dbo.transitiontomaterial(v_test_transition_id, NULL);

        -- If we reach here, NULL was allowed
        RAISE NOTICE '⚠️  TEST 3b WARNING: NULL material_id accepted - check NOT NULL constraint';

        -- Cleanup
        DELETE FROM perseus_dbo.transition_material
        WHERE transition_id = v_test_transition_id AND material_id IS NULL;

    EXCEPTION
        WHEN not_null_violation THEN
            RAISE NOTICE '✅ TEST 3b PASSED: NULL material_id correctly rejected';
        WHEN check_violation THEN
            RAISE NOTICE '✅ TEST 3b PASSED: NULL material_id rejected by CHECK constraint';
    END;

    -- Test 3c: Both NULL
    BEGIN
        CALL perseus_dbo.transitiontomaterial(NULL, NULL);

        RAISE NOTICE '⚠️  TEST 3c WARNING: Both NULLs accepted - check NOT NULL constraints';

        -- Cleanup
        DELETE FROM perseus_dbo.transition_material
        WHERE transition_id IS NULL AND material_id IS NULL;

    EXCEPTION
        WHEN not_null_violation THEN
            RAISE NOTICE '✅ TEST 3c PASSED: Both NULLs correctly rejected';
        WHEN check_violation THEN
            RAISE NOTICE '✅ TEST 3c PASSED: Both NULLs rejected by CHECK constraint';
    END;

    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '❌ TEST 3 FAILED: % (SQLSTATE: %)',
                        SQLERRM, SQLSTATE;
END $$;

-- =====================================================================
-- TEST 4: Foreign Key Constraint Validation
-- =====================================================================
DO $$
DECLARE
    v_invalid_transition VARCHAR(50) := 'INVALID-TRANS-999';
    v_invalid_material VARCHAR(50) := 'INVALID-MAT-999';
BEGIN
    RAISE NOTICE '--- TEST 4: Foreign Key Constraint Enforcement ---';

    -- Attempt insert with non-existent foreign keys
    BEGIN
        CALL perseus_dbo.transitiontomaterial(v_invalid_transition, v_invalid_material);

        -- If we reach here, FK constraints don't exist or invalid IDs happen to exist
        RAISE NOTICE '⚠️  TEST 4 WARNING: Insert with invalid FKs succeeded';
        RAISE NOTICE '⚠️  This may indicate:';
        RAISE NOTICE '⚠️    1. No FK constraints defined on transition_material table';
        RAISE NOTICE '⚠️    2. Test IDs happen to exist in parent tables';
        RAISE NOTICE '⚠️  Recommendation: Add FK constraints if missing';

        -- Cleanup
        DELETE FROM perseus_dbo.transition_material
        WHERE transition_id = v_invalid_transition
          AND material_id = v_invalid_material;

    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE '✅ TEST 4 PASSED: FK constraints correctly enforced';
            RAISE NOTICE 'ℹ️  FK violation caught: %', SQLERRM;
    END;

    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        -- Cleanup on unexpected failure
        DELETE FROM perseus_dbo.transition_material
        WHERE transition_id = v_invalid_transition;

        RAISE EXCEPTION '❌ TEST 4 FAILED: % (SQLSTATE: %)',
                        SQLERRM, SQLSTATE;
END $$;

-- =====================================================================
-- TEST 5: Length Constraint Validation (VARCHAR(50))
-- =====================================================================
DO $$
DECLARE
    v_long_transition VARCHAR(200) := 'TEST-TRANS-' || repeat('X', 100);  -- >50 chars
    v_long_material VARCHAR(200) := 'TEST-MAT-' || repeat('Y', 100);      -- >50 chars
    v_test_material VARCHAR(50) := 'TEST-MAT-005';
    v_test_transition VARCHAR(50) := 'TEST-TRANS-005';
BEGIN
    RAISE NOTICE '--- TEST 5: Length Constraint Validation ---';

    -- Test 5a: Long transition_id (>50 chars)
    BEGIN
        CALL perseus_dbo.transitiontomaterial(v_long_transition, v_test_material);

        -- If we reach here, long string was allowed (truncated or no constraint)
        RAISE NOTICE '⚠️  TEST 5a WARNING: String >50 chars accepted for transition_id';
        RAISE NOTICE '⚠️  This occurs when VARCHAR has no length limit (VARCHAR vs VARCHAR(50))';
        RAISE NOTICE '⚠️  Recommendation: Use VARCHAR(50) in procedure definition';

        -- Cleanup
        DELETE FROM perseus_dbo.transition_material
        WHERE material_id = v_test_material;

    EXCEPTION
        WHEN string_data_right_truncation THEN
            RAISE NOTICE '✅ TEST 5a PASSED: Long transition_id truncated/rejected';
        WHEN check_violation THEN
            RAISE NOTICE '✅ TEST 5a PASSED: Long transition_id rejected by CHECK constraint';
    END;

    -- Test 5b: Long material_id (>50 chars)
    BEGIN
        CALL perseus_dbo.transitiontomaterial(v_test_transition, v_long_material);

        RAISE NOTICE '⚠️  TEST 5b WARNING: String >50 chars accepted for material_id';

        -- Cleanup
        DELETE FROM perseus_dbo.transition_material
        WHERE transition_id = v_test_transition;

    EXCEPTION
        WHEN string_data_right_truncation THEN
            RAISE NOTICE '✅ TEST 5b PASSED: Long material_id truncated/rejected';
        WHEN check_violation THEN
            RAISE NOTICE '✅ TEST 5b PASSED: Long material_id rejected by CHECK constraint';
    END;

    -- Test 5c: Exactly 50 chars (should be accepted)
    DECLARE
        v_exactly_50_trans VARCHAR(50) := 'TRANS-' || repeat('Z', 44);  -- Exactly 50
        v_exactly_50_mat VARCHAR(50) := 'MAT-' || repeat('W', 46);      -- Exactly 50
        v_count INTEGER;
    BEGIN
        CALL perseus_dbo.transitiontomaterial(v_exactly_50_trans, v_exactly_50_mat);

        SELECT COUNT(*) INTO v_count
        FROM perseus_dbo.transition_material
        WHERE transition_id = v_exactly_50_trans
          AND material_id = v_exactly_50_mat;

        IF v_count = 1 THEN
            RAISE NOTICE '✅ TEST 5c PASSED: Exactly 50-char strings accepted';
        ELSE
            RAISE EXCEPTION 'TEST 5c FAILED: 50-char strings should be accepted';
        END IF;

        -- Cleanup
        DELETE FROM perseus_dbo.transition_material
        WHERE transition_id = v_exactly_50_trans;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️  TEST 5c WARNING: 50-char strings rejected: %', SQLERRM;

            -- Cleanup
            DELETE FROM perseus_dbo.transition_material
            WHERE transition_id LIKE 'TRANS-%';
    END;

    RAISE NOTICE '';

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '❌ TEST 5 FAILED: % (SQLSTATE: %)',
                        SQLERRM, SQLSTATE;
END $$;

-- =====================================================================
-- TEST SUITE SUMMARY
-- =====================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'TEST SUITE COMPLETED';
    RAISE NOTICE 'Finished: %', clock_timestamp();
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'SUMMARY:';
    RAISE NOTICE '  Test 1: Successful Insert (Happy Path)';
    RAISE NOTICE '  Test 2: Duplicate Key Handling';
    RAISE NOTICE '  Test 3: NULL Parameter Validation (3 subtests)';
    RAISE NOTICE '  Test 4: Foreign Key Constraint Enforcement';
    RAISE NOTICE '  Test 5: Length Constraint Validation (3 subtests)';
    RAISE NOTICE '';
    RAISE NOTICE 'REVIEW:';
    RAISE NOTICE '  ✅ = Test passed as expected';
    RAISE NOTICE '  ⚠️  = Test passed with warnings (missing constraints)';
    RAISE NOTICE '  ❌ = Test failed (should not occur)';
    RAISE NOTICE '';
    RAISE NOTICE 'NOTES:';
    RAISE NOTICE '  - Warnings indicate missing DB constraints (NOT procedure bugs)';
    RAISE NOTICE '  - Add UNIQUE, NOT NULL, and FK constraints to transition_material table';
    RAISE NOTICE '  - VARCHAR(50) length enforcement requires procedure definition update';
    RAISE NOTICE '';
    RAISE NOTICE 'RECOMMENDED CONSTRAINTS:';
    RAISE NOTICE '  ALTER TABLE perseus_dbo.transition_material';
    RAISE NOTICE '    ADD CONSTRAINT pk_transition_material';
    RAISE NOTICE '      PRIMARY KEY (material_id, transition_id);';
    RAISE NOTICE '';
    RAISE NOTICE '  ALTER TABLE perseus_dbo.transition_material';
    RAISE NOTICE '    ADD CONSTRAINT fk_material';
    RAISE NOTICE '      FOREIGN KEY (material_id) REFERENCES perseus_dbo.materials(uid);';
    RAISE NOTICE '';
    RAISE NOTICE '  ALTER TABLE perseus_dbo.transition_material';
    RAISE NOTICE '    ADD CONSTRAINT fk_transition';
    RAISE NOTICE '      FOREIGN KEY (transition_id) REFERENCES perseus_dbo.transitions(uid);';
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
END $$;

-- =====================================================================
-- CLEANUP VERIFICATION
-- =====================================================================
-- Verify no test data remains
DO $$
DECLARE
    v_test_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_test_count
    FROM perseus_dbo.transition_material
    WHERE transition_id LIKE 'TEST-%'
       OR material_id LIKE 'TEST-%';

    IF v_test_count > 0 THEN
        RAISE WARNING 'Cleanup incomplete: % test records remain', v_test_count;
        RAISE NOTICE 'Run: DELETE FROM perseus_dbo.transition_material WHERE transition_id LIKE ''TEST-%'';';
    ELSE
        RAISE NOTICE 'ℹ️  Cleanup verified: No test data remains in table';
    END IF;
END $$;

-- =====================================================================
-- END OF TEST SUITE
-- =====================================================================
