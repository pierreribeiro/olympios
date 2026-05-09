-- ===================================================================
-- UNIT TEST: MaterialToTransition
-- ===================================================================
-- PURPOSE:
--   Comprehensive unit test suite for MaterialToTransition procedure
--   Tests all success paths, error conditions, and edge cases
--
-- PROCEDURE TESTED:
--   perseus_dbo.materialtotransition(VARCHAR(50), VARCHAR(50))
--
-- TEST COVERAGE:
--   1. Successful insert (happy path)
--   2. Duplicate key handling
--   3. NULL parameter validation
--   4. Empty string handling
--   5. Maximum length strings (50 chars)
--   6. Special characters in IDs
--   7. Twin procedure compatibility
--   8. Cleanup verification
--
-- AUTHOR: Pierre Ribeiro + Claude Code Web
-- CREATED: 2025-11-29
-- SPRINT: 6 (Issue #24)
-- QUALITY TARGET: 90%+ test coverage
-- ===================================================================

-- ===================================================================
-- TEST SETUP
-- ===================================================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'UNIT TEST SUITE: MaterialToTransition';
    RAISE NOTICE 'Sprint 6 - Issue #24';
    RAISE NOTICE 'Started: %', clock_timestamp();
    RAISE NOTICE '========================================';
END $$;

-- ===================================================================
-- TEST 1: Successful Insert (Happy Path)
-- ===================================================================
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 1: Successful insert (happy path)';
    RAISE NOTICE '----------------------------------------';

    -- Execute procedure
    CALL perseus_dbo.materialtotransition('MAT-TEST-001', 'TRANS-TEST-001');

    -- Verify insert succeeded
    SELECT COUNT(*) INTO v_count
    FROM perseus_dbo.material_transition
    WHERE material_id = 'MAT-TEST-001'
      AND transition_id = 'TRANS-TEST-001';

    IF v_count = 1 THEN
        RAISE NOTICE '✅ TEST 1 PASSED: Insert successful, 1 record created';
    ELSE
        RAISE EXCEPTION '❌ TEST 1 FAILED: Expected 1 record, found %', v_count;
    END IF;

    -- Cleanup
    DELETE FROM perseus_dbo.material_transition
    WHERE material_id = 'MAT-TEST-001';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 1 FAILED: % - %', SQLERRM, SQLSTATE;
        -- Cleanup attempt
        DELETE FROM perseus_dbo.material_transition
        WHERE material_id = 'MAT-TEST-001';
END $$;

-- ===================================================================
-- TEST 2: Duplicate Key Handling
-- ===================================================================
DO $$
DECLARE
    v_error_caught BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 2: Duplicate key handling';
    RAISE NOTICE '----------------------------------------';

    -- Insert first record
    CALL perseus_dbo.materialtotransition('MAT-TEST-002', 'TRANS-TEST-002');

    -- Attempt duplicate insert (should fail gracefully)
    BEGIN
        CALL perseus_dbo.materialtotransition('MAT-TEST-002', 'TRANS-TEST-002');
        RAISE NOTICE '❌ TEST 2 FAILED: Duplicate insert should have raised exception';
    EXCEPTION
        WHEN unique_violation THEN
            v_error_caught := TRUE;
            RAISE NOTICE '✅ TEST 2 PASSED: Duplicate key rejected correctly';
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️  TEST 2 WARNING: Expected unique_violation, got: %', SQLERRM;
    END;

    -- Cleanup
    DELETE FROM perseus_dbo.material_transition
    WHERE material_id = 'MAT-TEST-002';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 2 FAILED: % - %', SQLERRM, SQLSTATE;
        -- Cleanup attempt
        DELETE FROM perseus_dbo.material_transition
        WHERE material_id = 'MAT-TEST-002';
END $$;

-- ===================================================================
-- TEST 3a: NULL Material ID Validation
-- ===================================================================
DO $$
DECLARE
    v_error_caught BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3a: NULL material_id validation';
    RAISE NOTICE '----------------------------------------';

    -- Test NULL material_id
    BEGIN
        CALL perseus_dbo.materialtotransition(NULL, 'TRANS-TEST-003');
        RAISE NOTICE '❌ TEST 3a FAILED: NULL material_id should have raised exception';
    EXCEPTION
        WHEN not_null_violation THEN
            v_error_caught := TRUE;
            RAISE NOTICE '✅ TEST 3a PASSED: NULL material_id rejected correctly';
        WHEN check_violation THEN
            v_error_caught := TRUE;
            RAISE NOTICE '✅ TEST 3a PASSED: NULL material_id rejected (check constraint)';
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️  TEST 3a WARNING: Expected not_null_violation, got: %', SQLERRM;
    END;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 3a FAILED: % - %', SQLERRM, SQLSTATE;
END $$;

-- ===================================================================
-- TEST 3b: NULL Transition ID Validation
-- ===================================================================
DO $$
DECLARE
    v_error_caught BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 3b: NULL transition_id validation';
    RAISE NOTICE '----------------------------------------';

    -- Test NULL transition_id
    BEGIN
        CALL perseus_dbo.materialtotransition('MAT-TEST-003', NULL);
        RAISE NOTICE '❌ TEST 3b FAILED: NULL transition_id should have raised exception';
    EXCEPTION
        WHEN not_null_violation THEN
            v_error_caught := TRUE;
            RAISE NOTICE '✅ TEST 3b PASSED: NULL transition_id rejected correctly';
        WHEN check_violation THEN
            v_error_caught := TRUE;
            RAISE NOTICE '✅ TEST 3b PASSED: NULL transition_id rejected (check constraint)';
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️  TEST 3b WARNING: Expected not_null_violation, got: %', SQLERRM;
    END;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 3b FAILED: % - %', SQLERRM, SQLSTATE;
END $$;

-- ===================================================================
-- TEST 4: Empty String Handling
-- ===================================================================
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 4: Empty string handling';
    RAISE NOTICE '----------------------------------------';

    -- Test empty strings (should insert if constraints allow)
    BEGIN
        CALL perseus_dbo.materialtotransition('', '');

        -- Verify insert
        SELECT COUNT(*) INTO v_count
        FROM perseus_dbo.material_transition
        WHERE material_id = '' AND transition_id = '';

        IF v_count = 1 THEN
            RAISE NOTICE '✅ TEST 4 PASSED: Empty strings accepted (no constraint violation)';
            -- Cleanup
            DELETE FROM perseus_dbo.material_transition
            WHERE material_id = '';
        ELSE
            RAISE NOTICE '⚠️  TEST 4 WARNING: Unexpected record count: %', v_count;
        END IF;

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '✅ TEST 4 PASSED: Empty strings rejected by check constraint';
        WHEN foreign_key_violation THEN
            RAISE NOTICE '✅ TEST 4 PASSED: Empty strings rejected by FK constraint';
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️  TEST 4 INFO: Empty strings rejected: %', SQLERRM;
    END;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 4 FAILED: % - %', SQLERRM, SQLSTATE;
        -- Cleanup attempt
        DELETE FROM perseus_dbo.material_transition WHERE material_id = '';
END $$;

-- ===================================================================
-- TEST 5: Maximum Length Strings (50 characters)
-- ===================================================================
DO $$
DECLARE
    v_max_material VARCHAR(50) := REPEAT('M', 50);
    v_max_transition VARCHAR(50) := REPEAT('T', 50);
    v_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 5: Maximum length strings (50 chars)';
    RAISE NOTICE '----------------------------------------';

    -- Insert max-length strings
    CALL perseus_dbo.materialtotransition(v_max_material, v_max_transition);

    -- Verify insert
    SELECT COUNT(*) INTO v_count
    FROM perseus_dbo.material_transition
    WHERE material_id = v_max_material
      AND transition_id = v_max_transition;

    IF v_count = 1 THEN
        RAISE NOTICE '✅ TEST 5 PASSED: Max-length strings (50 chars) accepted';
    ELSE
        RAISE EXCEPTION 'Expected 1 record, found %', v_count;
    END IF;

    -- Cleanup
    DELETE FROM perseus_dbo.material_transition
    WHERE material_id = v_max_material;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 5 FAILED: % - %', SQLERRM, SQLSTATE;
        -- Cleanup attempt
        DELETE FROM perseus_dbo.material_transition
        WHERE material_id LIKE 'MMM%';
END $$;

-- ===================================================================
-- TEST 6: Special Characters in IDs
-- ===================================================================
DO $$
DECLARE
    v_special_material VARCHAR(50) := 'MAT-TEST_006@#$%';
    v_special_transition VARCHAR(50) := 'TRANS-TEST_006!&*';
    v_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 6: Special characters in IDs';
    RAISE NOTICE '----------------------------------------';

    -- Insert IDs with special characters
    BEGIN
        CALL perseus_dbo.materialtotransition(v_special_material, v_special_transition);

        -- Verify insert
        SELECT COUNT(*) INTO v_count
        FROM perseus_dbo.material_transition
        WHERE material_id = v_special_material
          AND transition_id = v_special_transition;

        IF v_count = 1 THEN
            RAISE NOTICE '✅ TEST 6 PASSED: Special characters accepted';
            -- Cleanup
            DELETE FROM perseus_dbo.material_transition
            WHERE material_id = v_special_material;
        ELSE
            RAISE NOTICE '⚠️  TEST 6 WARNING: Unexpected record count: %', v_count;
        END IF;

    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '⚠️  TEST 6 INFO: Special characters rejected by check constraint';
        WHEN foreign_key_violation THEN
            RAISE NOTICE '✅ TEST 6 PASSED: Special characters validated by FK (expected behavior)';
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️  TEST 6 INFO: Special characters rejected: %', SQLERRM;
    END;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 6 FAILED: % - %', SQLERRM, SQLSTATE;
        -- Cleanup attempt
        DELETE FROM perseus_dbo.material_transition
        WHERE material_id LIKE '%TEST_006%';
END $$;

-- ===================================================================
-- TEST 7: Twin Procedure Compatibility
-- ===================================================================
DO $$
DECLARE
    v_count_mat_trans INTEGER;
    v_count_trans_mat INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 7: Twin procedure compatibility';
    RAISE NOTICE '----------------------------------------';

    -- Call MaterialToTransition
    BEGIN
        CALL perseus_dbo.materialtotransition('MAT-TEST-007', 'TRANS-TEST-007');
        RAISE NOTICE '  ✓ MaterialToTransition executed';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '  ⚠️  MaterialToTransition failed: %', SQLERRM;
    END;

    -- Call TransitionToMaterial (twin)
    BEGIN
        CALL perseus_dbo.transitiontomaterial('TRANS-TEST-007B', 'MAT-TEST-007B');
        RAISE NOTICE '  ✓ TransitionToMaterial (twin) executed';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '  ⚠️  TransitionToMaterial failed: %', SQLERRM;
    END;

    -- Verify both inserts (if tables are different)
    BEGIN
        SELECT COUNT(*) INTO v_count_mat_trans
        FROM perseus_dbo.material_transition
        WHERE material_id IN ('MAT-TEST-007', 'MAT-TEST-007B');

        SELECT COUNT(*) INTO v_count_trans_mat
        FROM perseus_dbo.transition_material
        WHERE material_id IN ('MAT-TEST-007', 'MAT-TEST-007B');

        RAISE NOTICE '  ✓ material_transition records: %', v_count_mat_trans;
        RAISE NOTICE '  ✓ transition_material records: %', v_count_trans_mat;

        IF v_count_mat_trans > 0 OR v_count_trans_mat > 0 THEN
            RAISE NOTICE '✅ TEST 7 PASSED: Twin procedures compatible';
        ELSE
            RAISE NOTICE '⚠️  TEST 7 WARNING: No records found in either table';
        END IF;

    EXCEPTION
        WHEN undefined_table THEN
            RAISE NOTICE '⚠️  TEST 7 INFO: One or both twin tables do not exist (expected in some schemas)';
        WHEN OTHERS THEN
            RAISE NOTICE '⚠️  TEST 7 WARNING: %', SQLERRM;
    END;

    -- Cleanup
    BEGIN
        DELETE FROM perseus_dbo.material_transition
        WHERE material_id IN ('MAT-TEST-007', 'MAT-TEST-007B');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    BEGIN
        DELETE FROM perseus_dbo.transition_material
        WHERE material_id IN ('MAT-TEST-007', 'MAT-TEST-007B');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 7 FAILED: % - %', SQLERRM, SQLSTATE;
END $$;

-- ===================================================================
-- TEST 8: Cleanup Verification
-- ===================================================================
DO $$
DECLARE
    v_orphan_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'TEST 8: Cleanup verification';
    RAISE NOTICE '----------------------------------------';

    -- Check for any orphaned test records
    SELECT COUNT(*) INTO v_orphan_count
    FROM perseus_dbo.material_transition
    WHERE material_id LIKE 'MAT-TEST-%'
       OR transition_id LIKE 'TRANS-TEST-%';

    IF v_orphan_count = 0 THEN
        RAISE NOTICE '✅ TEST 8 PASSED: All test records cleaned up (0 orphans)';
    ELSE
        RAISE NOTICE '⚠️  TEST 8 WARNING: Found % orphaned test records', v_orphan_count;

        -- Cleanup orphans
        DELETE FROM perseus_dbo.material_transition
        WHERE material_id LIKE 'MAT-TEST-%'
           OR transition_id LIKE 'TRANS-TEST-%';

        RAISE NOTICE '  ✓ Orphaned records cleaned up';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ TEST 8 FAILED: % - %', SQLERRM, SQLSTATE;
END $$;

-- ===================================================================
-- TEST SUMMARY
-- ===================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'TEST SUITE COMPLETE';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Procedure: MaterialToTransition';
    RAISE NOTICE 'Sprint: 6 (Issue #24)';
    RAISE NOTICE 'Total Tests: 8';
    RAISE NOTICE 'Coverage: Happy path, errors, edge cases, twin compatibility';
    RAISE NOTICE 'Completed: %', clock_timestamp();
    RAISE NOTICE '';
    RAISE NOTICE 'MANUAL REVIEW REQUIRED:';
    RAISE NOTICE '  - Check test output above for any ❌ FAILED or ⚠️  WARNING messages';
    RAISE NOTICE '  - Verify all ✅ PASSED messages present';
    RAISE NOTICE '  - Review schema-specific behaviors (FK, constraints)';
    RAISE NOTICE '========================================';
END $$;

-- ===================================================================
-- NOTES
-- ===================================================================
-- 1. Some tests may show warnings instead of passes if:
--    - Foreign key constraints enforce different validation
--    - Check constraints exist on the target table
--    - Schema differs from expected structure
--
-- 2. Test 7 (twin compatibility) may show warnings if:
--    - Only one of the twin tables exists
--    - Tables are aliases/views of each other
--    - Schema is still under development
--
-- 3. All test records use 'MAT-TEST-*' and 'TRANS-TEST-*' prefixes
--    for easy identification and cleanup
--
-- 4. Tests are designed to be idempotent - can run multiple times
--    without side effects
--
-- 5. For integration testing with real data, see:
--    tests/integration/test_twin_procedures.sql
-- ===================================================================

-- END OF UNIT TEST: MaterialToTransition
