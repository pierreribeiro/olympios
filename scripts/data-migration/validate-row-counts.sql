-- ============================================================================
-- PostgreSQL Row Count Validation Script
-- Perseus Database Migration: DEV Environment Data Validation
-- ============================================================================
-- Purpose: Validate 15% sampling rate for all loaded tables
-- Prerequisites: Data loaded via load-data.sh
-- Usage: psql -U perseus_admin -d perseus_dev -f validate-row-counts.sql
-- ============================================================================

\set ON_ERROR_STOP on
\timing on

SET search_path TO perseus, public;

\echo '========================================'
\echo 'ROW COUNT VALIDATION'
\echo 'Target: 15% ±2% variance acceptable'
\echo '========================================'
\echo ''

-- ============================================================================
-- Create temporary table for results
-- ============================================================================
CREATE TEMPORARY TABLE row_count_validation (
    tier INTEGER,
    table_name VARCHAR(100),
    target_rows INTEGER,
    actual_rows INTEGER,
    expected_pct NUMERIC(5,2),
    actual_pct NUMERIC(5,2),
    variance_pct NUMERIC(5,2),
    status VARCHAR(20)
) ON COMMIT DROP;

-- ============================================================================
-- TIER 0: Base Tables (15% random sample)
-- ============================================================================
\echo 'TIER 0: Base Tables (15% random sample)'
\echo ''

-- Note: Source row counts are examples - replace with actual SQL Server counts
-- These values should come from PerseusTableAndRowCounts or direct COUNT(*) queries

INSERT INTO row_count_validation VALUES
(0, 'Permissions', NULL, (SELECT COUNT(*) FROM perseus.Permissions), 15.00, NULL, NULL, 'INFO'),
(0, 'PerseusTableAndRowCounts', NULL, (SELECT COUNT(*) FROM perseus.PerseusTableAndRowCounts), 15.00, NULL, NULL, 'INFO'),
(0, 'Scraper', NULL, (SELECT COUNT(*) FROM perseus.Scraper), 15.00, NULL, NULL, 'INFO'),
(0, 'unit', NULL, (SELECT COUNT(*) FROM perseus.unit), 15.00, NULL, NULL, 'INFO'),
(0, 'recipe_category', NULL, (SELECT COUNT(*) FROM perseus.recipe_category), 15.00, NULL, NULL, 'INFO'),
(0, 'recipe_type', NULL, (SELECT COUNT(*) FROM perseus.recipe_type), 15.00, NULL, NULL, 'INFO'),
(0, 'run_type', NULL, (SELECT COUNT(*) FROM perseus.run_type), 15.00, NULL, NULL, 'INFO'),
(0, 'transition_type', NULL, (SELECT COUNT(*) FROM perseus.transition_type), 15.00, NULL, NULL, 'INFO'),
(0, 'workflow_type', NULL, (SELECT COUNT(*) FROM perseus.workflow_type), 15.00, NULL, NULL, 'INFO'),
(0, 'poll', NULL, (SELECT COUNT(*) FROM perseus.poll), 15.00, NULL, NULL, 'INFO'),
(0, 'cm_unit_dimensions', NULL, (SELECT COUNT(*) FROM perseus.cm_unit_dimensions), 15.00, NULL, NULL, 'INFO'),
(0, 'cm_user', NULL, (SELECT COUNT(*) FROM perseus.cm_user), 15.00, NULL, NULL, 'INFO'),
(0, 'cm_user_group', NULL, (SELECT COUNT(*) FROM perseus.cm_user_group), 15.00, NULL, NULL, 'INFO'),
(0, 'coa', NULL, (SELECT COUNT(*) FROM perseus.coa), 15.00, NULL, NULL, 'INFO'),
(0, 'coa_spec', NULL, (SELECT COUNT(*) FROM perseus.coa_spec), 15.00, NULL, NULL, 'INFO'),
(0, 'color', NULL, (SELECT COUNT(*) FROM perseus.color), 15.00, NULL, NULL, 'INFO'),
(0, 'container', NULL, (SELECT COUNT(*) FROM perseus.container), 15.00, NULL, NULL, 'INFO'),
(0, 'container_type', NULL, (SELECT COUNT(*) FROM perseus.container_type), 15.00, NULL, NULL, 'INFO'),
(0, 'goo_type', NULL, (SELECT COUNT(*) FROM perseus.goo_type), 15.00, NULL, NULL, 'INFO'),
(0, 'manufacturer', NULL, (SELECT COUNT(*) FROM perseus.manufacturer), 15.00, NULL, NULL, 'INFO'),
(0, 'display_layout', NULL, (SELECT COUNT(*) FROM perseus.display_layout), 15.00, NULL, NULL, 'INFO'),
(0, 'display_type', NULL, (SELECT COUNT(*) FROM perseus.display_type), 15.00, NULL, NULL, 'INFO'),
(0, 'm_downstream', NULL, (SELECT COUNT(*) FROM perseus.m_downstream), 15.00, NULL, NULL, 'INFO'),
(0, 'external_goo_type', NULL, (SELECT COUNT(*) FROM perseus.external_goo_type), 15.00, NULL, NULL, 'INFO'),
(0, 'm_upstream', NULL, (SELECT COUNT(*) FROM perseus.m_upstream), 15.00, NULL, NULL, 'INFO'),
(0, 'm_upstream_dirty_leaves', NULL, (SELECT COUNT(*) FROM perseus.m_upstream_dirty_leaves), 15.00, NULL, NULL, 'INFO'),
(0, 'goo_type_property_def', NULL, (SELECT COUNT(*) FROM perseus.goo_type_property_def), 15.00, NULL, NULL, 'INFO'),
(0, 'field_map', NULL, (SELECT COUNT(*) FROM perseus.field_map), 15.00, NULL, NULL, 'INFO'),
(0, 'goo_qc', NULL, (SELECT COUNT(*) FROM perseus.goo_qc), 15.00, NULL, NULL, 'INFO'),
(0, 'smurf_robot', NULL, (SELECT COUNT(*) FROM perseus.smurf_robot), 15.00, NULL, NULL, 'INFO'),
(0, 'smurf_robot_part', NULL, (SELECT COUNT(*) FROM perseus.smurf_robot_part), 15.00, NULL, NULL, 'INFO'),
(0, 'property_type', NULL, (SELECT COUNT(*) FROM perseus.property_type), 15.00, NULL, NULL, 'INFO');

-- ============================================================================
-- TIER 1: Tables with Tier 0 Dependencies
-- ============================================================================
\echo 'TIER 1: Tables with Tier 0 Dependencies'
\echo ''

INSERT INTO row_count_validation VALUES
(1, 'property', NULL, (SELECT COUNT(*) FROM perseus.property), 15.00, NULL, NULL, 'INFO'),
(1, 'robot_log_type', NULL, (SELECT COUNT(*) FROM perseus.robot_log_type), 15.00, NULL, NULL, 'INFO'),
(1, 'container_type_position', NULL, (SELECT COUNT(*) FROM perseus.container_type_position), 15.00, NULL, NULL, 'INFO'),
(1, 'goo_type_combine_target', NULL, (SELECT COUNT(*) FROM perseus.goo_type_combine_target), 15.00, NULL, NULL, 'INFO'),
(1, 'container_history', NULL, (SELECT COUNT(*) FROM perseus.container_history), 15.00, NULL, NULL, 'INFO'),
(1, 'workflow', NULL, (SELECT COUNT(*) FROM perseus.workflow), 15.00, NULL, NULL, 'INFO'),
(1, 'perseus_user', NULL, (SELECT COUNT(*) FROM perseus.perseus_user), 15.00, NULL, NULL, 'INFO'),
(1, 'field_map_display_type', NULL, (SELECT COUNT(*) FROM perseus.field_map_display_type), 15.00, NULL, NULL, 'INFO'),
(1, 'field_map_display_type_user', NULL, (SELECT COUNT(*) FROM perseus.field_map_display_type_user), 15.00, NULL, NULL, 'INFO');

-- ============================================================================
-- TIER 2: Tables with Tier 0-1 Dependencies
-- ============================================================================
\echo 'TIER 2: Tables with Tier 0-1 Dependencies'
\echo ''

INSERT INTO row_count_validation VALUES
(2, 'feed_type', NULL, (SELECT COUNT(*) FROM perseus.feed_type), 15.00, NULL, NULL, 'INFO'),
(2, 'goo_type_combine_component', NULL, (SELECT COUNT(*) FROM perseus.goo_type_combine_component), 15.00, NULL, NULL, 'INFO'),
(2, 'material_inventory_threshold', NULL, (SELECT COUNT(*) FROM perseus.material_inventory_threshold), 15.00, NULL, NULL, 'INFO'),
(2, 'material_inventory_threshold_notify_user', NULL, (SELECT COUNT(*) FROM perseus.material_inventory_threshold_notify_user), 15.00, NULL, NULL, 'INFO'),
(2, 'workflow_section', NULL, (SELECT COUNT(*) FROM perseus.workflow_section), 15.00, NULL, NULL, 'INFO'),
(2, 'workflow_attachment', NULL, (SELECT COUNT(*) FROM perseus.workflow_attachment), 15.00, NULL, NULL, 'INFO'),
(2, 'workflow_step', NULL, (SELECT COUNT(*) FROM perseus.workflow_step), 15.00, NULL, NULL, 'INFO'),
(2, 'recipe', NULL, (SELECT COUNT(*) FROM perseus.recipe), 15.00, NULL, NULL, 'INFO'),
(2, 'smurf_group', NULL, (SELECT COUNT(*) FROM perseus.smurf_group), 15.00, NULL, NULL, 'INFO'),
(2, 'smurf_goo_type', NULL, (SELECT COUNT(*) FROM perseus.smurf_goo_type), 15.00, NULL, NULL, 'INFO'),
(2, 'property_option', NULL, (SELECT COUNT(*) FROM perseus.property_option), 15.00, NULL, NULL, 'INFO');

-- ============================================================================
-- TIER 3: Tables with Tier 0-2 Dependencies (INCLUDING P0 CRITICAL)
-- ============================================================================
\echo 'TIER 3: Tables with Tier 0-2 Dependencies'
\echo 'Including P0 CRITICAL: goo, fatsmurf'
\echo ''

INSERT INTO row_count_validation VALUES
(3, 'goo', NULL, (SELECT COUNT(*) FROM perseus.goo), 15.00, NULL, NULL, 'P0 CRITICAL'),
(3, 'fatsmurf', NULL, (SELECT COUNT(*) FROM perseus.fatsmurf), 15.00, NULL, NULL, 'P0 CRITICAL'),
(3, 'goo_attachment', NULL, (SELECT COUNT(*) FROM perseus.goo_attachment), 15.00, NULL, NULL, 'INFO'),
(3, 'goo_comment', NULL, (SELECT COUNT(*) FROM perseus.goo_comment), 15.00, NULL, NULL, 'INFO'),
(3, 'goo_history', NULL, (SELECT COUNT(*) FROM perseus.goo_history), 15.00, NULL, NULL, 'INFO'),
(3, 'fatsmurf_attachment', NULL, (SELECT COUNT(*) FROM perseus.fatsmurf_attachment), 15.00, NULL, NULL, 'INFO'),
(3, 'fatsmurf_comment', NULL, (SELECT COUNT(*) FROM perseus.fatsmurf_comment), 15.00, NULL, NULL, 'INFO'),
(3, 'fatsmurf_history', NULL, (SELECT COUNT(*) FROM perseus.fatsmurf_history), 15.00, NULL, NULL, 'INFO'),
(3, 'recipe_part', NULL, (SELECT COUNT(*) FROM perseus.recipe_part), 15.00, NULL, NULL, 'INFO'),
(3, 'smurf', NULL, (SELECT COUNT(*) FROM perseus.smurf), 15.00, NULL, NULL, 'INFO'),
(3, 'submission', NULL, (SELECT COUNT(*) FROM perseus.submission), 15.00, NULL, NULL, 'INFO'),
(3, 'material_qc', NULL, (SELECT COUNT(*) FROM perseus.material_qc), 15.00, NULL, NULL, 'INFO');

-- ============================================================================
-- TIER 4: Highest Dependency Tables (INCLUDING P0 LINEAGE)
-- ============================================================================
\echo 'TIER 4: Highest Dependency Tables'
\echo 'Including P0 CRITICAL LINEAGE: material_transition, transition_material'
\echo ''

INSERT INTO row_count_validation VALUES
(4, 'material_transition', NULL, (SELECT COUNT(*) FROM perseus.material_transition), 15.00, NULL, NULL, 'P0 CRITICAL'),
(4, 'transition_material', NULL, (SELECT COUNT(*) FROM perseus.transition_material), 15.00, NULL, NULL, 'P0 CRITICAL'),
(4, 'material_inventory', NULL, (SELECT COUNT(*) FROM perseus.material_inventory), 15.00, NULL, NULL, 'INFO'),
(4, 'fatsmurf_reading', NULL, (SELECT COUNT(*) FROM perseus.fatsmurf_reading), 15.00, NULL, NULL, 'INFO'),
(4, 'poll_history', NULL, (SELECT COUNT(*) FROM perseus.poll_history), 15.00, NULL, NULL, 'INFO'),
(4, 'submission_entry', NULL, (SELECT COUNT(*) FROM perseus.submission_entry), 15.00, NULL, NULL, 'INFO'),
(4, 'robot_log', NULL, (SELECT COUNT(*) FROM perseus.robot_log), 15.00, NULL, NULL, 'INFO'),
(4, 'robot_log_read', NULL, (SELECT COUNT(*) FROM perseus.robot_log_read), 15.00, NULL, NULL, 'INFO'),
(4, 'robot_log_transfer', NULL, (SELECT COUNT(*) FROM perseus.robot_log_transfer), 15.00, NULL, NULL, 'INFO'),
(4, 'robot_log_error', NULL, (SELECT COUNT(*) FROM perseus.robot_log_error), 15.00, NULL, NULL, 'INFO'),
(4, 'robot_log_container_sequence', NULL, (SELECT COUNT(*) FROM perseus.robot_log_container_sequence), 15.00, NULL, NULL, 'INFO');

-- ============================================================================
-- DISPLAY RESULTS
-- ============================================================================
\echo ''
\echo '========================================'
\echo 'ROW COUNT REPORT'
\echo '========================================'
\echo ''

SELECT
    tier AS "Tier",
    table_name AS "Table Name",
    actual_rows AS "Rows Loaded",
    status AS "Notes"
FROM row_count_validation
ORDER BY tier, table_name;

\echo ''
\echo '========================================'
\echo 'SUMMARY STATISTICS'
\echo '========================================'
\echo ''

-- Summary by tier
SELECT
    tier AS "Tier",
    COUNT(*) AS "Tables",
    SUM(actual_rows) AS "Total Rows",
    TO_CHAR(AVG(actual_rows), 'FM999,999') AS "Avg Rows/Table"
FROM row_count_validation
GROUP BY tier
ORDER BY tier;

\echo ''
SELECT
    'TOTAL' AS "Level",
    COUNT(*) AS "Tables",
    SUM(actual_rows) AS "Total Rows Loaded"
FROM row_count_validation;

\echo ''
\echo 'P0 CRITICAL TABLE COUNTS:'
SELECT
    table_name AS "Table",
    actual_rows AS "Rows"
FROM row_count_validation
WHERE status LIKE '%P0%'
ORDER BY table_name;

\echo ''
\echo '========================================'
\echo 'VARIANCE ANALYSIS'
\echo '========================================'
\echo ''
\echo 'NOTE: To calculate variance, you need source row counts.'
\echo 'Update this script with actual SQL Server counts from:'
\echo '  - PerseusTableAndRowCounts table'
\echo '  - OR direct COUNT(*) queries on SQL Server'
\echo ''
\echo 'Then re-run with variance calculation:'
\echo '  actual_pct = (actual_rows / source_rows) * 100'
\echo '  variance_pct = actual_pct - 15.00'
\echo ''
\echo 'Acceptable variance: ±2% (13% to 17%)'
\echo '========================================'

-- ============================================================================
-- VARIANCE CALCULATION (requires source counts)
-- ============================================================================
-- Uncomment and populate once you have SQL Server source counts

/*
-- Update with actual source counts
UPDATE row_count_validation SET target_rows = <SQL_SERVER_COUNT> WHERE table_name = 'goo';
UPDATE row_count_validation SET target_rows = <SQL_SERVER_COUNT> WHERE table_name = 'fatsmurf';
-- ... repeat for all tables

-- Calculate percentages and variance
UPDATE row_count_validation
SET
    actual_pct = ROUND((actual_rows::NUMERIC / NULLIF(target_rows, 0)) * 100, 2),
    variance_pct = ROUND((actual_rows::NUMERIC / NULLIF(target_rows, 0)) * 100 - 15.00, 2);

-- Set status based on variance
UPDATE row_count_validation
SET status = CASE
    WHEN variance_pct BETWEEN -2.0 AND 2.0 THEN '✓ PASS'
    WHEN variance_pct BETWEEN -5.0 AND 5.0 THEN '⚠ WARNING'
    ELSE '✗ FAIL'
END
WHERE target_rows IS NOT NULL;

-- Display variance report
SELECT
    tier,
    table_name,
    target_rows AS "Source Rows",
    actual_rows AS "Loaded Rows",
    expected_pct || '%' AS "Target %",
    actual_pct || '%' AS "Actual %",
    variance_pct || '%' AS "Variance",
    status
FROM row_count_validation
WHERE target_rows IS NOT NULL
ORDER BY ABS(variance_pct) DESC;
*/

\echo ''
\echo 'Validation complete. Review results above.'
