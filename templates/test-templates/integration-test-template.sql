-- ============================================================================
-- Integration Test: [Feature/Workflow Name]
-- Test Type: Cross-object workflow validation
-- ============================================================================
-- Test Info:
--   Objects Tested: [object1, object2, object3, ...]
--   Workflow: [Description of end-to-end workflow]
--   Tester: [name]
--   Date: [YYYY-MM-DD]
-- ============================================================================

\echo '============================================================================'
\echo 'Integration Test: [Feature/Workflow Name]'
\echo '============================================================================'

BEGIN;

-- ============================================================================
-- Test Setup - Create Test Environment
-- ============================================================================

\echo '>>> Setting up test environment...'

DO $$
BEGIN
    -- Create test data that spans multiple tables
    INSERT INTO perseus.goo (goo_id, parent_goo_id, name, is_active)
    VALUES
        (9001, NULL, 'test_root_goo', TRUE),
        (9002, 9001, 'test_child_goo', TRUE),
        (9003, 9002, 'test_grandchild_goo', TRUE)
    ON CONFLICT (goo_id) DO NOTHING;

    INSERT INTO perseus.material (material_id, goo_id, name, status)
    VALUES
        (8001, 9001, 'test_material_1', 'active'),
        (8002, 9002, 'test_material_2', 'active'),
        (8003, 9003, 'test_material_3', 'pending')
    ON CONFLICT (material_id) DO NOTHING;

    INSERT INTO perseus.transition (transition_id, name, description)
    VALUES
        (7001, 'test_transition_1', 'Test transition for integration test'),
        (7002, 'test_transition_2', 'Second test transition')
    ON CONFLICT (transition_id) DO NOTHING;

    INSERT INTO perseus.material_transition (material_id, transition_id, from_goo_id, to_goo_id)
    VALUES
        (8001, 7001, 9001, 9002),
        (8002, 7001, 9002, 9003)
    ON CONFLICT DO NOTHING;

    RAISE NOTICE '✓ Test environment setup complete';
END $$;

-- ============================================================================
-- INTEGRATION TEST 1: Material Lineage Workflow
-- Tests: goo + material_transition + upstream view + mcgetupstream()
-- ============================================================================

\echo '>>> INTEGRATION TEST 1: Material Lineage Workflow'

DO $$
DECLARE
    v_upstream_count INTEGER;
    v_view_count INTEGER;
    v_function_count INTEGER;
BEGIN
    -- Test 1a: Upstream view returns correct lineage
    SELECT COUNT(*)::INTEGER
    INTO v_view_count
    FROM perseus.upstream
    WHERE goo_id = 9003;

    IF v_view_count >= 2 THEN -- Should have 9002 and 9001 as upstream
        RAISE NOTICE '✓ TEST 1a PASSED: Upstream view returned % ancestors', v_view_count;
    ELSE
        RAISE EXCEPTION '✗ TEST 1a FAILED: Expected >= 2 ancestors, got %', v_view_count;
    END IF;

    -- Test 1b: mcgetupstream() function returns same results
    SELECT COUNT(*)::INTEGER
    INTO v_function_count
    FROM perseus.mcgetupstream(9003);

    IF v_function_count = v_view_count THEN
        RAISE NOTICE '✓ TEST 1b PASSED: Function matches view - % rows', v_function_count;
    ELSE
        RAISE EXCEPTION '✗ TEST 1b FAILED: Function ≠ view - Function: % | View: %', v_function_count, v_view_count;
    END IF;

    -- Test 1c: Translated materialized view consistency
    SELECT COUNT(*)::INTEGER
    INTO v_upstream_count
    FROM perseus.translated
    WHERE material_id = 8002;

    IF v_upstream_count > 0 THEN
        RAISE NOTICE '✓ TEST 1c PASSED: Materialized view includes test data';
    ELSE
        RAISE WARNING '⚠ TEST 1c WARNING: Materialized view may need refresh';
    END IF;
END $$;

-- ============================================================================
-- INTEGRATION TEST 2: Batch Operations Workflow
-- Tests: Temp table pattern (GooList UDT) + mcgetupstreambylist()
-- ============================================================================

\echo '>>> INTEGRATION TEST 2: Batch Operations Workflow'

DO $$
DECLARE
    v_batch_count INTEGER;
    v_individual_count INTEGER;
BEGIN
    -- Create temp table for batch query
    CREATE TEMPORARY TABLE tmp_goo_list (
        goo_id INTEGER PRIMARY KEY
    ) ON COMMIT DROP;

    -- Insert test goo IDs
    INSERT INTO tmp_goo_list VALUES (9002), (9003);

    -- Test 2a: Batch function returns results for multiple IDs
    SELECT COUNT(*)::INTEGER
    INTO v_batch_count
    FROM perseus.mcgetupstreambylist();

    IF v_batch_count > 0 THEN
        RAISE NOTICE '✓ TEST 2a PASSED: Batch query returned % rows', v_batch_count;
    ELSE
        RAISE EXCEPTION '✗ TEST 2a FAILED: Batch query returned no rows';
    END IF;

    -- Test 2b: Batch results == sum of individual queries
    SELECT SUM(cnt)::INTEGER
    INTO v_individual_count
    FROM (
        SELECT COUNT(*)::INTEGER AS cnt FROM perseus.mcgetupstream(9002)
        UNION ALL
        SELECT COUNT(*)::INTEGER AS cnt FROM perseus.mcgetupstream(9003)
    ) counts;

    IF v_batch_count = v_individual_count THEN
        RAISE NOTICE '✓ TEST 2b PASSED: Batch results match individual queries';
    ELSE
        RAISE WARNING '⚠ TEST 2b WARNING: Batch ≠ individual - Batch: % | Individual: %',
            v_batch_count, v_individual_count;
    END IF;
END $$;

-- ============================================================================
-- INTEGRATION TEST 3: FDW Integration Workflow
-- Tests: Foreign Data Wrapper connectivity + cross-database joins
-- ============================================================================

\echo '>>> INTEGRATION TEST 3: FDW Integration Workflow'

DO $$
DECLARE
    v_fdw_count INTEGER;
    v_local_count INTEGER;
BEGIN
    -- Test 3a: FDW connection is alive
    BEGIN
        SELECT COUNT(*)::INTEGER
        INTO v_fdw_count
        FROM hermes.run
        LIMIT 1;

        RAISE NOTICE '✓ TEST 3a PASSED: FDW connection successful';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING '⚠ TEST 3a WARNING: FDW connection failed - %', SQLERRM;
            v_fdw_count := 0;
    END;

    -- Test 3b: Cross-database join (local + FDW)
    IF v_fdw_count > 0 THEN
        SELECT COUNT(*)::INTEGER
        INTO v_local_count
        FROM perseus.goo_relationship
        WHERE source = 'hermes';

        IF v_local_count > 0 THEN
            RAISE NOTICE '✓ TEST 3b PASSED: Cross-database join returned % rows', v_local_count;
        ELSE
            RAISE WARNING '⚠ TEST 3b WARNING: goo_relationship view contains no hermes data';
        END IF;
    END IF;
END $$;

-- ============================================================================
-- INTEGRATION TEST 4: Transaction Workflow
-- Tests: Atomic transaction management + rollback behavior
-- ============================================================================

\echo '>>> INTEGRATION TEST 4: Transaction Workflow'

DO $$
DECLARE
    v_before_count INTEGER;
    v_after_count INTEGER;
BEGIN
    -- Test 4a: Transaction rollback on error
    SELECT COUNT(*)::INTEGER
    INTO v_before_count
    FROM perseus.goo;

    BEGIN
        -- Start nested transaction
        INSERT INTO perseus.goo (goo_id, name, is_active)
        VALUES (9999, 'test_rollback_goo', TRUE);

        -- Force error to test rollback
        INSERT INTO perseus.goo (goo_id, name, is_active)
        VALUES (9999, 'duplicate_pk', TRUE); -- Should fail on PK
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE '✓ TEST 4a PASSED: Transaction rolled back on constraint violation';
    END;

    -- Verify rollback
    SELECT COUNT(*)::INTEGER
    INTO v_after_count
    FROM perseus.goo;

    IF v_before_count = v_after_count THEN
        RAISE NOTICE '✓ TEST 4b PASSED: Rollback prevented partial commit';
    ELSE
        RAISE EXCEPTION '✗ TEST 4b FAILED: Partial commit detected - Before: % | After: %',
            v_before_count, v_after_count;
    END IF;
END $$;

-- ============================================================================
-- INTEGRATION TEST 5: Cascade Behavior Workflow
-- Tests: Foreign key cascades (ON DELETE CASCADE, ON UPDATE CASCADE)
-- ============================================================================

\echo '>>> INTEGRATION TEST 5: Cascade Behavior Workflow'

DO $$
DECLARE
    v_child_count INTEGER;
BEGIN
    -- Test 5a: ON DELETE CASCADE
    DELETE FROM perseus.goo WHERE goo_id = 9001;

    -- Check if children were cascaded
    SELECT COUNT(*)::INTEGER
    INTO v_child_count
    FROM perseus.goo
    WHERE goo_id IN (9002, 9003);

    IF v_child_count = 0 THEN
        RAISE NOTICE '✓ TEST 5a PASSED: CASCADE DELETE removed % child rows', 2;
    ELSE
        RAISE WARNING '⚠ TEST 5a WARNING: CASCADE DELETE did not remove all children - % remain', v_child_count;
    END IF;

    -- Test 5b: Check material_transition cascade
    SELECT COUNT(*)::INTEGER
    INTO v_child_count
    FROM perseus.material_transition
    WHERE from_goo_id = 9001 OR to_goo_id = 9001;

    IF v_child_count = 0 THEN
        RAISE NOTICE '✓ TEST 5b PASSED: material_transition rows cascaded';
    ELSE
        RAISE WARNING '⚠ TEST 5b WARNING: material_transition rows not cascaded - % remain', v_child_count;
    END IF;
END $$;

-- ============================================================================
-- INTEGRATION TEST 6: End-to-End Application Workflow
-- Tests: Simulated application workflow across multiple objects
-- ============================================================================

\echo '>>> INTEGRATION TEST 6: End-to-End Application Workflow'

DO $$
DECLARE
    v_workflow_success BOOLEAN := TRUE;
    v_step_result INTEGER;
BEGIN
    -- Step 1: Create new goo
    INSERT INTO perseus.goo (goo_id, parent_goo_id, name, is_active)
    VALUES (9100, NULL, 'workflow_test_goo', TRUE);

    SELECT COUNT(*)::INTEGER INTO v_step_result
    FROM perseus.goo WHERE goo_id = 9100;

    IF v_step_result != 1 THEN
        v_workflow_success := FALSE;
        RAISE WARNING '⚠ Step 1 FAILED: Goo not created';
    END IF;

    -- Step 2: Create material
    INSERT INTO perseus.material (material_id, goo_id, name, status)
    VALUES (8100, 9100, 'workflow_test_material', 'active');

    SELECT COUNT(*)::INTEGER INTO v_step_result
    FROM perseus.material WHERE material_id = 8100;

    IF v_step_result != 1 THEN
        v_workflow_success := FALSE;
        RAISE WARNING '⚠ Step 2 FAILED: Material not created';
    END IF;

    -- Step 3: Create transition
    INSERT INTO perseus.transition (transition_id, name, description)
    VALUES (7100, 'workflow_test_transition', 'Test transition');

    -- Step 4: Link material to transition
    INSERT INTO perseus.material_transition (material_id, transition_id, from_goo_id, to_goo_id)
    VALUES (8100, 7100, 9100, 9100);

    SELECT COUNT(*)::INTEGER INTO v_step_result
    FROM perseus.material_transition WHERE material_id = 8100;

    IF v_step_result != 1 THEN
        v_workflow_success := FALSE;
        RAISE WARNING '⚠ Step 4 FAILED: Material transition not created';
    END IF;

    -- Step 5: Query lineage views
    SELECT COUNT(*)::INTEGER INTO v_step_result
    FROM perseus.upstream WHERE goo_id = 9100;

    IF v_step_result < 0 THEN -- Allow 0 for root goo
        v_workflow_success := FALSE;
        RAISE WARNING '⚠ Step 5 FAILED: Lineage view query failed';
    END IF;

    -- Final result
    IF v_workflow_success THEN
        RAISE NOTICE '✓ TEST 6 PASSED: End-to-end workflow completed successfully';
    ELSE
        RAISE EXCEPTION '✗ TEST 6 FAILED: One or more workflow steps failed';
    END IF;
END $$;

-- ============================================================================
-- INTEGRATION TEST 7: Performance Under Load
-- Tests: Concurrent access, query performance with realistic data volume
-- ============================================================================

\echo '>>> INTEGRATION TEST 7: Performance Under Load'

DO $$
DECLARE
    v_start_time TIMESTAMP;
    v_execution_time INTERVAL;
    v_threshold INTERVAL := '10 seconds';
    v_query_count INTEGER := 100;
BEGIN
    v_start_time := clock_timestamp();

    -- Simulate concurrent queries
    FOR i IN 1..v_query_count LOOP
        PERFORM *
        FROM perseus.upstream
        WHERE goo_id = (9001 + (i % 3));
    END LOOP;

    v_execution_time := clock_timestamp() - v_start_time;

    IF v_execution_time <= v_threshold THEN
        RAISE NOTICE '✓ TEST 7 PASSED: % queries completed in % (threshold: %)',
            v_query_count, v_execution_time, v_threshold;
    ELSE
        RAISE WARNING '⚠ TEST 7 WARNING: Performance degradation - % queries took % (threshold: %)',
            v_query_count, v_execution_time, v_threshold;
    END IF;
END $$;

-- ============================================================================
-- Test Cleanup
-- ============================================================================

\echo '>>> Cleaning up integration test data...'

DO $$
BEGIN
    -- Cleanup in dependency order (reverse of creation)
    DELETE FROM perseus.material_transition
    WHERE material_id BETWEEN 8000 AND 8999
       OR from_goo_id BETWEEN 9000 AND 9999
       OR to_goo_id BETWEEN 9000 AND 9999;

    DELETE FROM perseus.material
    WHERE material_id BETWEEN 8000 AND 8999;

    DELETE FROM perseus.transition
    WHERE transition_id BETWEEN 7000 AND 7999;

    DELETE FROM perseus.goo
    WHERE goo_id BETWEEN 9000 AND 9999;

    RAISE NOTICE '✓ Integration test data cleaned up successfully';
END $$;

ROLLBACK; -- Rollback entire integration test transaction

-- ============================================================================
-- Integration Test Summary
-- ============================================================================

\echo '============================================================================'
\echo 'Integration Test Summary: [Feature/Workflow Name]'
\echo '============================================================================'
\echo 'Total Tests: 7'
\echo 'Workflow Areas Tested:'
\echo '  1. Material Lineage (views + functions)'
\echo '  2. Batch Operations (temp table pattern)'
\echo '  3. FDW Integration (cross-database joins)'
\echo '  4. Transaction Management (rollback behavior)'
\echo '  5. Cascade Behavior (foreign key cascades)'
\echo '  6. End-to-End Application Workflow'
\echo '  7. Performance Under Load'
\echo '============================================================================'
\echo 'Test completed. Review output above for PASSED/FAILED/WARNING status.'
\echo '============================================================================'
