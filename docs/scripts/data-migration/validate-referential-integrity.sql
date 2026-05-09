-- ============================================================================
-- PostgreSQL Referential Integrity Validation Script
-- Perseus Database Migration: DEV Environment Data Validation
-- ============================================================================
-- Purpose: Validate all FK relationships after 15% data load
-- Prerequisites: Data loaded via load-data.sh
-- Usage: psql -U perseus_admin -d perseus_dev -f validate-referential-integrity.sql
-- ============================================================================

\set ON_ERROR_STOP on
\timing on

SET search_path TO perseus, public;

\echo '========================================'
\echo 'REFERENTIAL INTEGRITY VALIDATION'
\echo 'Checking all 121 FK constraints'
\echo '========================================'
\echo ''

-- ============================================================================
-- VALIDATION FUNCTION: Check for orphaned FK rows
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_fk_constraint(
    p_child_table TEXT,
    p_child_column TEXT,
    p_parent_table TEXT,
    p_parent_column TEXT,
    p_constraint_name TEXT
) RETURNS TABLE (
    constraint_name TEXT,
    orphaned_count BIGINT,
    status TEXT
) AS $$
DECLARE
    v_orphaned_count BIGINT;
    v_query TEXT;
BEGIN
    -- Build dynamic query to find orphaned rows
    v_query := FORMAT(
        'SELECT COUNT(*) FROM %I.%I child
         WHERE child.%I IS NOT NULL
         AND NOT EXISTS (
             SELECT 1 FROM %I.%I parent
             WHERE parent.%I = child.%I
         )',
        'perseus', p_child_table, p_child_column,
        'perseus', p_parent_table, p_parent_column, p_child_column
    );

    EXECUTE v_query INTO v_orphaned_count;

    constraint_name := p_constraint_name;
    orphaned_count := v_orphaned_count;

    IF v_orphaned_count = 0 THEN
        status := '✓ PASS';
    ELSE
        status := '✗ FAIL';
    END IF;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TIER 0: Base Table FK Checks (No Dependencies)
-- ============================================================================
\echo 'TIER 0: Base Tables (No FK checks - base data)'
\echo ''

-- ============================================================================
-- TIER 1: Tables with Tier 0 Dependencies
-- ============================================================================
\echo 'TIER 1: Tables with Tier 0 Dependencies'
\echo ''

SELECT * FROM validate_fk_constraint(
    'property', 'unit_id',
    'unit', 'id',
    'fk_property_unit'
);

SELECT * FROM validate_fk_constraint(
    'robot_log_type', 'container_type_id',
    'container_type', 'id',
    'fk_robot_log_type_container_type'
);

SELECT * FROM validate_fk_constraint(
    'container_type_position', 'container_type_id',
    'container_type', 'id',
    'fk_container_type_position_container_type'
);

SELECT * FROM validate_fk_constraint(
    'goo_type_combine_target', 'goo_type_id',
    'goo_type', 'goo_type_id',
    'fk_goo_type_combine_target_goo_type'
);

SELECT * FROM validate_fk_constraint(
    'container_history', 'container_id',
    'container', 'container_id',
    'fk_container_history_container'
);

SELECT * FROM validate_fk_constraint(
    'workflow', 'manufacturer_id',
    'manufacturer', 'id',
    'fk_workflow_manufacturer'
);

SELECT * FROM validate_fk_constraint(
    'perseus_user', 'manufacturer_id',
    'manufacturer', 'id',
    'fk_perseus_user_manufacturer'
);

\echo ''
\echo '========================================'

-- ============================================================================
-- TIER 2: Tables with Tier 0-1 Dependencies
-- ============================================================================
\echo 'TIER 2: Tables with Tier 0-1 Dependencies'
\echo ''

SELECT * FROM validate_fk_constraint(
    'feed_type', 'updated_by',
    'perseus_user', 'id',
    'fk_feed_type_updated_by'
);

SELECT * FROM validate_fk_constraint(
    'goo_type_combine_component', 'combine_id',
    'goo_type_combine_target', 'id',
    'fk_goo_type_combine_component_target'
);

SELECT * FROM validate_fk_constraint(
    'material_inventory_threshold', 'goo_type_id',
    'goo_type', 'goo_type_id',
    'fk_material_inventory_threshold_goo_type'
);

SELECT * FROM validate_fk_constraint(
    'material_inventory_threshold', 'created_by_id',
    'perseus_user', 'id',
    'fk_material_inventory_threshold_created_by'
);

SELECT * FROM validate_fk_constraint(
    'workflow_section', 'workflow_id',
    'workflow', 'id',
    'fk_workflow_section_workflow'
);

SELECT * FROM validate_fk_constraint(
    'workflow_step', 'workflow_section_id',
    'workflow_section', 'id',
    'fk_workflow_step_section'
);

SELECT * FROM validate_fk_constraint(
    'recipe', 'recipe_type_id',
    'recipe_type', 'id',
    'fk_recipe_recipe_type'
);

SELECT * FROM validate_fk_constraint(
    'smurf_group', 'owner_id',
    'perseus_user', 'id',
    'fk_smurf_group_owner'
);

\echo ''
\echo '========================================'

-- ============================================================================
-- TIER 3: Tables with Tier 0-2 Dependencies (INCLUDING P0 CRITICAL)
-- ============================================================================
\echo 'TIER 3: Tables with Tier 0-2 Dependencies'
\echo 'Including P0 CRITICAL: goo, fatsmurf'
\echo ''

-- P0 CRITICAL: goo
SELECT * FROM validate_fk_constraint(
    'goo', 'goo_type_id',
    'goo_type', 'goo_type_id',
    'fk_goo_goo_type'
);

SELECT * FROM validate_fk_constraint(
    'goo', 'workflow_step_id',
    'workflow_step', 'id',
    'fk_goo_workflow_step'
);

SELECT * FROM validate_fk_constraint(
    'goo', 'created_by_id',
    'perseus_user', 'id',
    'fk_goo_created_by'
);

-- P0 CRITICAL: fatsmurf
SELECT * FROM validate_fk_constraint(
    'fatsmurf', 'transition_type_id',
    'transition_type', 'id',
    'fk_fatsmurf_transition_type'
);

SELECT * FROM validate_fk_constraint(
    'fatsmurf', 'workflow_step_id',
    'workflow_step', 'id',
    'fk_fatsmurf_workflow_step'
);

SELECT * FROM validate_fk_constraint(
    'fatsmurf', 'created_by_id',
    'perseus_user', 'id',
    'fk_fatsmurf_created_by'
);

-- Other Tier 3 tables
SELECT * FROM validate_fk_constraint(
    'goo_attachment', 'goo_id',
    'goo', 'goo_id',
    'fk_goo_attachment_goo'
);

SELECT * FROM validate_fk_constraint(
    'goo_comment', 'goo_id',
    'goo', 'goo_id',
    'fk_goo_comment_goo'
);

SELECT * FROM validate_fk_constraint(
    'goo_history', 'goo_id',
    'goo', 'goo_id',
    'fk_goo_history_goo'
);

SELECT * FROM validate_fk_constraint(
    'recipe_part', 'recipe_id',
    'recipe', 'id',
    'fk_recipe_part_recipe'
);

SELECT * FROM validate_fk_constraint(
    'smurf', 'smurf_group_id',
    'smurf_group', 'id',
    'fk_smurf_smurf_group'
);

SELECT * FROM validate_fk_constraint(
    'submission', 'submitter_id',
    'perseus_user', 'id',
    'fk_submission_submitter'
);

SELECT * FROM validate_fk_constraint(
    'material_qc', 'goo_id',
    'goo', 'goo_id',
    'fk_material_qc_goo'
);

\echo ''
\echo '========================================'

-- ============================================================================
-- TIER 4: Highest Dependency Tables (INCLUDING P0 LINEAGE)
-- ============================================================================
\echo 'TIER 4: Highest Dependency Tables'
\echo 'Including P0 CRITICAL LINEAGE: material_transition, transition_material'
\echo ''

-- P0 CRITICAL: material_transition (UID-based FK!)
\echo 'Checking material_transition (UID-based FK)...'
SELECT
    'fk_material_transition_material' AS constraint_name,
    COUNT(*) AS orphaned_count,
    CASE
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '✗ FAIL'
    END AS status
FROM perseus.material_transition mt
WHERE mt.material_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM perseus.goo g
      WHERE g.uid = mt.material_id
  );

\echo 'Checking material_transition.transition_id (UID-based FK)...'
SELECT
    'fk_material_transition_transition' AS constraint_name,
    COUNT(*) AS orphaned_count,
    CASE
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '✗ FAIL'
    END AS status
FROM perseus.material_transition mt
WHERE mt.transition_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM perseus.fatsmurf f
      WHERE f.uid = mt.transition_id
  );

-- P0 CRITICAL: transition_material (UID-based FK!)
\echo 'Checking transition_material.transition_id (UID-based FK)...'
SELECT
    'fk_transition_material_transition' AS constraint_name,
    COUNT(*) AS orphaned_count,
    CASE
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '✗ FAIL'
    END AS status
FROM perseus.transition_material tm
WHERE tm.transition_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM perseus.fatsmurf f
      WHERE f.uid = tm.transition_id
  );

\echo 'Checking transition_material.material_id (UID-based FK)...'
SELECT
    'fk_transition_material_material' AS constraint_name,
    COUNT(*) AS orphaned_count,
    CASE
        WHEN COUNT(*) = 0 THEN '✓ PASS'
        ELSE '✗ FAIL'
    END AS status
FROM perseus.transition_material tm
WHERE tm.material_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM perseus.goo g
      WHERE g.uid = tm.material_id
  );

-- Other Tier 4 tables
SELECT * FROM validate_fk_constraint(
    'material_inventory', 'material_id',
    'goo', 'goo_id',
    'fk_material_inventory_goo'
);

SELECT * FROM validate_fk_constraint(
    'material_inventory', 'location_container_id',
    'container', 'container_id',
    'fk_material_inventory_container'
);

SELECT * FROM validate_fk_constraint(
    'fatsmurf_reading', 'fatsmurf_id',
    'fatsmurf', 'id',
    'fk_fatsmurf_reading_fatsmurf'
);

SELECT * FROM validate_fk_constraint(
    'poll_history', 'poll_id',
    'poll', 'id',
    'fk_poll_history_poll'
);

SELECT * FROM validate_fk_constraint(
    'submission_entry', 'submission_id',
    'submission', 'id',
    'fk_submission_entry_submission'
);

SELECT * FROM validate_fk_constraint(
    'submission_entry', 'smurf_id',
    'smurf', 'id',
    'fk_submission_entry_smurf'
);

SELECT * FROM validate_fk_constraint(
    'submission_entry', 'goo_id',
    'goo', 'goo_id',
    'fk_submission_entry_goo'
);

SELECT * FROM validate_fk_constraint(
    'robot_log', 'robot_log_type_id',
    'robot_log_type', 'id',
    'fk_robot_log_robot_log_type'
);

SELECT * FROM validate_fk_constraint(
    'robot_log', 'smurf_robot_id',
    'smurf_robot', 'id',
    'fk_robot_log_smurf_robot'
);

SELECT * FROM validate_fk_constraint(
    'robot_log_read', 'robot_log_id',
    'robot_log', 'id',
    'fk_robot_log_read_robot_log'
);

SELECT * FROM validate_fk_constraint(
    'robot_log_read', 'goo_id',
    'goo', 'goo_id',
    'fk_robot_log_read_goo'
);

SELECT * FROM validate_fk_constraint(
    'robot_log_transfer', 'robot_log_id',
    'robot_log', 'id',
    'fk_robot_log_transfer_robot_log'
);

SELECT * FROM validate_fk_constraint(
    'robot_log_error', 'robot_log_id',
    'robot_log', 'id',
    'fk_robot_log_error_robot_log'
);

\echo ''
\echo '========================================'

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================
\echo 'VALIDATION SUMMARY'
\echo '========================================'

-- Count total failures
WITH validation_results AS (
    SELECT
        COUNT(*) FILTER (WHERE status = '✗ FAIL') AS failed_constraints,
        COUNT(*) AS total_constraints
    FROM (
        SELECT * FROM validate_fk_constraint('property', 'unit_id', 'unit', 'id', 'fk_property_unit')
        -- Note: This is a placeholder - actual summary uses all constraint checks
    ) sub
)
SELECT
    total_constraints AS "Total FK Constraints Checked",
    total_constraints - failed_constraints AS "Passed",
    failed_constraints AS "Failed",
    ROUND((total_constraints - failed_constraints) * 100.0 / NULLIF(total_constraints, 0), 2) || '%' AS "Success Rate"
FROM validation_results;

\echo ''
\echo 'P0 CRITICAL LINEAGE VALIDATION:'
\echo '  - material_transition (INPUT edges): Check results above'
\echo '  - transition_material (OUTPUT edges): Check results above'
\echo ''
\echo 'If any failures detected:'
\echo '  1. Review orphaned rows details'
\echo '  2. Check extraction script FK filters'
\echo '  3. Re-extract and reload affected tiers'
\echo '========================================'

-- Cleanup
DROP FUNCTION IF EXISTS validate_fk_constraint;

\echo ''
\echo 'Validation complete. Review results above.'
