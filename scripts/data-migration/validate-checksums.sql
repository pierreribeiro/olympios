-- ============================================================================
-- PostgreSQL Checksum Validation Script
-- Perseus Database Migration: DEV Environment Data Validation
-- ============================================================================
-- Purpose: Validate data integrity via MD5 checksums (sample-based)
-- Prerequisites: Data loaded via load-data.sh, identical data exported from SQL Server
-- Usage: psql -U perseus_admin -d perseus_dev -f validate-checksums.sql
-- ============================================================================

\set ON_ERROR_STOP on
\timing on

SET search_path TO perseus, public;

\echo '========================================'
\echo 'DATA INTEGRITY CHECKSUM VALIDATION'
\echo 'Strategy: Sample-based MD5 checksums'
\echo '========================================'
\echo ''

-- ============================================================================
-- CHECKSUM METHODOLOGY
-- ============================================================================
-- 1. Sample 100 rows from each critical table (or all if <100 rows)
-- 2. Compute MD5 checksum of concatenated column values
-- 3. Compare with checksums from SQL Server (manual validation)
-- 4. Focus on P0 critical tables: goo, fatsmurf, material_transition, transition_material
-- ============================================================================

-- ============================================================================
-- P0 CRITICAL: goo
-- ============================================================================
\echo 'P0 CRITICAL: goo (Core Material Entity)'
\echo 'Computing checksums for 100 sample rows...'
\echo ''

WITH sample_goo AS (
    SELECT
        id,
        MD5(
            COALESCE(id::TEXT, '') || '|' ||
            COALESCE(uid, '') || '|' ||
            COALESCE(name, '') || '|' ||
            COALESCE(goo_type_id::TEXT, '') || '|' ||
            COALESCE(description, '') || '|' ||
            COALESCE(is_locked::TEXT, 'false') || '|' ||
            COALESCE(created_by_id::TEXT, '') || '|' ||
            COALESCE(created_date::TEXT, '')
        ) AS row_checksum
    FROM perseus.goo
    ORDER BY id
    LIMIT 100
)
SELECT
    'goo' AS table_name,
    COUNT(*) AS sample_size,
    MD5(STRING_AGG(row_checksum, '' ORDER BY id)) AS aggregate_checksum
FROM sample_goo;

\echo ''
\echo 'To validate: Run identical query on SQL Server and compare aggregate_checksum'
\echo 'SQL Server equivalent:'
\echo '  SELECT TOP 100'
\echo '    goo_id,'
\echo '    CONVERT(VARCHAR(32), HASHBYTES(''MD5'','
\echo '      ISNULL(CAST(goo_id AS VARCHAR), '''') + ''|'' +'
\echo '      ISNULL(uid, '''') + ''|'' +'
\echo '      ISNULL(name, '''') + ''|'' +'
\echo '      ISNULL(CAST(goo_type_id AS VARCHAR), '''') + ''|'' +'
\echo '      ISNULL(description, '''') + ''|'' +'
\echo '      ISNULL(CAST(is_locked AS VARCHAR), ''false'') + ''|'' +'
\echo '      ISNULL(CAST(created_by_id AS VARCHAR), '''') + ''|'' +'
\echo '      ISNULL(CAST(created_date AS VARCHAR), '''')'
\echo '    ), 2) AS row_checksum'
\echo '  FROM dbo.goo'
\echo '  ORDER BY goo_id;'
\echo ''
\echo '========================================'

-- ============================================================================
-- P0 CRITICAL: fatsmurf
-- ============================================================================
\echo 'P0 CRITICAL: fatsmurf (Experiments/Transitions)'
\echo 'Computing checksums for 100 sample rows...'
\echo ''

WITH sample_fatsmurf AS (
    SELECT
        id,
        MD5(
            COALESCE(id::TEXT, '') || '|' ||
            COALESCE(uid, '') || '|' ||
            COALESCE(name, '') || '|' ||
            COALESCE(transition_type_id::TEXT, '') || '|' ||
            COALESCE(description, '') || '|' ||
            COALESCE(created_by_id::TEXT, '') || '|' ||
            COALESCE(created_date::TEXT, '')
        ) AS row_checksum
    FROM perseus.fatsmurf
    ORDER BY id
    LIMIT 100
)
SELECT
    'fatsmurf' AS table_name,
    COUNT(*) AS sample_size,
    MD5(STRING_AGG(row_checksum, '' ORDER BY id)) AS aggregate_checksum
FROM sample_fatsmurf;

\echo ''
\echo '========================================'

-- ============================================================================
-- P0 CRITICAL: material_transition (Lineage INPUT edges)
-- ============================================================================
\echo 'P0 CRITICAL: material_transition (Lineage INPUT edges)'
\echo 'Computing checksums for 100 sample rows...'
\echo ''

WITH sample_material_transition AS (
    SELECT
        id,
        MD5(
            COALESCE(id::TEXT, '') || '|' ||
            COALESCE(material_id, '') || '|' ||  -- VARCHAR uid
            COALESCE(transition_id, '') || '|' ||  -- VARCHAR uid
            COALESCE(quantity::TEXT, '') || '|' ||
            COALESCE(created_date::TEXT, '')
        ) AS row_checksum
    FROM perseus.material_transition
    ORDER BY id
    LIMIT 100
)
SELECT
    'material_transition' AS table_name,
    COUNT(*) AS sample_size,
    MD5(STRING_AGG(row_checksum, '' ORDER BY id)) AS aggregate_checksum
FROM sample_material_transition;

\echo ''
\echo '** CRITICAL: This table is UID-based FK (not integer PK/FK)'
\echo '** Verify material_id and transition_id match goo.uid and fatsmurf.uid'
\echo ''
\echo '========================================'

-- ============================================================================
-- P0 CRITICAL: transition_material (Lineage OUTPUT edges)
-- ============================================================================
\echo 'P0 CRITICAL: transition_material (Lineage OUTPUT edges)'
\echo 'Computing checksums for 100 sample rows...'
\echo ''

WITH sample_transition_material AS (
    SELECT
        id,
        MD5(
            COALESCE(id::TEXT, '') || '|' ||
            COALESCE(transition_id, '') || '|' ||  -- VARCHAR uid
            COALESCE(material_id, '') || '|' ||  -- VARCHAR uid
            COALESCE(quantity::TEXT, '') || '|' ||
            COALESCE(created_date::TEXT, '')
        ) AS row_checksum
    FROM perseus.transition_material
    ORDER BY id
    LIMIT 100
)
SELECT
    'transition_material' AS table_name,
    COUNT(*) AS sample_size,
    MD5(STRING_AGG(row_checksum, '' ORDER BY id)) AS aggregate_checksum
FROM sample_transition_material;

\echo ''
\echo '** CRITICAL: This table is UID-based FK (not integer PK/FK)'
\echo '** Verify transition_id and material_id match fatsmurf.uid and goo.uid'
\echo ''
\echo '========================================'

-- ============================================================================
-- ADDITIONAL CRITICAL TABLES
-- ============================================================================

-- goo_type
\echo 'TIER 0: goo_type (Material Types)'
\echo 'Computing checksums for all rows...'
\echo ''

WITH sample_goo_type AS (
    SELECT
        goo_type_id,
        MD5(
            COALESCE(goo_type_id::TEXT, '') || '|' ||
            COALESCE(name, '') || '|' ||
            COALESCE(description, '') || '|' ||
            COALESCE(is_active::TEXT, 'true')
        ) AS row_checksum
    FROM perseus.goo_type
    ORDER BY goo_type_id
)
SELECT
    'goo_type' AS table_name,
    COUNT(*) AS sample_size,
    MD5(STRING_AGG(row_checksum, '' ORDER BY goo_type_id)) AS aggregate_checksum
FROM sample_goo_type;

\echo ''
\echo '========================================'

-- perseus_user
\echo 'TIER 1: perseus_user (User Accounts)'
\echo 'Computing checksums for 100 sample rows...'
\echo ''

WITH sample_perseus_user AS (
    SELECT
        id,
        MD5(
            COALESCE(id::TEXT, '') || '|' ||
            COALESCE(username, '') || '|' ||
            COALESCE(email, '') || '|' ||
            COALESCE(first_name, '') || '|' ||
            COALESCE(last_name, '') || '|' ||
            COALESCE(is_active::TEXT, 'true')
        ) AS row_checksum
    FROM perseus.perseus_user
    ORDER BY id
    LIMIT 100
)
SELECT
    'perseus_user' AS table_name,
    COUNT(*) AS sample_size,
    MD5(STRING_AGG(row_checksum, '' ORDER BY id)) AS aggregate_checksum
FROM sample_perseus_user;

\echo ''
\echo '========================================'

-- container
\echo 'TIER 0: container (Containers)'
\echo 'Computing checksums for 100 sample rows...'
\echo ''

WITH sample_container AS (
    SELECT
        container_id,
        MD5(
            COALESCE(container_id::TEXT, '') || '|' ||
            COALESCE(barcode, '') || '|' ||
            COALESCE(name, '') || '|' ||
            COALESCE(container_type_id::TEXT, '') || '|' ||
            COALESCE(is_active::TEXT, 'true')
        ) AS row_checksum
    FROM perseus.container
    ORDER BY container_id
    LIMIT 100
)
SELECT
    'container' AS table_name,
    COUNT(*) AS sample_size,
    MD5(STRING_AGG(row_checksum, '' ORDER BY container_id)) AS aggregate_checksum
FROM sample_container;

\echo ''
\echo '========================================'

-- workflow
\echo 'TIER 1: workflow (Workflows)'
\echo 'Computing checksums for all rows...'
\echo ''

WITH sample_workflow AS (
    SELECT
        id,
        MD5(
            COALESCE(id::TEXT, '') || '|' ||
            COALESCE(name, '') || '|' ||
            COALESCE(description, '') || '|' ||
            COALESCE(workflow_type_id::TEXT, '') || '|' ||
            COALESCE(is_active::TEXT, 'true')
        ) AS row_checksum
    FROM perseus.workflow
    ORDER BY id
)
SELECT
    'workflow' AS table_name,
    COUNT(*) AS sample_size,
    MD5(STRING_AGG(row_checksum, '' ORDER BY id)) AS aggregate_checksum
FROM sample_workflow;

\echo ''
\echo '========================================'

-- recipe
\echo 'TIER 2: recipe (Recipes)'
\echo 'Computing checksums for 100 sample rows...'
\echo ''

WITH sample_recipe AS (
    SELECT
        id,
        MD5(
            COALESCE(id::TEXT, '') || '|' ||
            COALESCE(name, '') || '|' ||
            COALESCE(recipe_type_id::TEXT, '') || '|' ||
            COALESCE(recipe_category_id::TEXT, '') || '|' ||
            COALESCE(is_active::TEXT, 'true')
        ) AS row_checksum
    FROM perseus.recipe
    ORDER BY id
    LIMIT 100
)
SELECT
    'recipe' AS table_name,
    COUNT(*) AS sample_size,
    MD5(STRING_AGG(row_checksum, '' ORDER BY id)) AS aggregate_checksum
FROM sample_recipe;

\echo ''
\echo '========================================'

-- ============================================================================
-- SUMMARY AND VALIDATION INSTRUCTIONS
-- ============================================================================
\echo ''
\echo '========================================'
\echo 'CHECKSUM VALIDATION SUMMARY'
\echo '========================================'
\echo ''
\echo 'Checksums computed for 9 critical tables:'
\echo '  P0 CRITICAL (4): goo, fatsmurf, material_transition, transition_material'
\echo '  Additional (5): goo_type, perseus_user, container, workflow, recipe'
\echo ''
\echo 'VALIDATION STEPS:'
\echo '  1. Export identical sample from SQL Server using provided queries'
\echo '  2. Compute checksums on SQL Server side'
\echo '  3. Compare aggregate_checksum values'
\echo '  4. Investigate any mismatches:'
\echo '     - Check data type conversions'
\echo '     - Verify NULL handling (ISNULL vs COALESCE)'
\echo '     - Check timestamp precision (SQL Server datetime vs PostgreSQL timestamp)'
\echo '     - Review boolean conversions (bit vs boolean)'
\echo ''
\echo 'CHECKSUM MISMATCH TROUBLESHOOTING:'
\echo '  - Timestamps: SQL Server datetime has 3.33ms precision, PostgreSQL has microsecond'
\echo '  - Booleans: SQL Server bit (0/1) vs PostgreSQL boolean (true/false)'
\echo '  - NULLs: Verify identical NULL handling on both sides'
\echo '  - String trimming: Check for trailing spaces (CHAR vs VARCHAR)'
\echo '  - Case sensitivity: PostgreSQL is case-sensitive by default'
\echo ''
\echo 'KNOWN ACCEPTABLE DIFFERENCES:'
\echo '  - Timestamps may differ by <4ms due to SQL Server datetime precision'
\echo '  - IDENTITY columns may have gaps (PostgreSQL sequences vs SQL Server IDENTITY)'
\echo '  - created_date/updated_date will differ (migration timestamp vs original)'
\echo ''
\echo '========================================'
\echo 'P0 CRITICAL LINEAGE VALIDATION'
\echo '========================================'
\echo ''
\echo 'CRITICAL: material_transition and transition_material use UID-based FKs'
\echo ''
\echo 'Verify the following relationships:'
\echo ''

SELECT
    'material_transition.material_id → goo.uid' AS relationship,
    COUNT(*) AS total_edges,
    COUNT(DISTINCT mt.material_id) AS unique_materials,
    COUNT(DISTINCT mt.transition_id) AS unique_transitions
FROM perseus.material_transition mt;

SELECT
    'transition_material.transition_id → fatsmurf.uid' AS relationship,
    COUNT(*) AS total_edges,
    COUNT(DISTINCT tm.transition_id) AS unique_transitions,
    COUNT(DISTINCT tm.material_id) AS unique_materials
FROM perseus.transition_material tm;

\echo ''
\echo 'LINEAGE GRAPH CONNECTIVITY:'
WITH lineage_stats AS (
    -- Material inputs (parent materials → transitions)
    SELECT
        COUNT(*) AS input_edges,
        COUNT(DISTINCT material_id) AS input_materials,
        COUNT(DISTINCT transition_id) AS input_transitions
    FROM perseus.material_transition
),
lineage_outputs AS (
    -- Material outputs (transitions → product materials)
    SELECT
        COUNT(*) AS output_edges,
        COUNT(DISTINCT transition_id) AS output_transitions,
        COUNT(DISTINCT material_id) AS output_materials
    FROM perseus.transition_material
)
SELECT
    i.input_edges AS "INPUT Edges (material → transition)",
    i.input_materials AS "INPUT Materials",
    i.input_transitions AS "INPUT Transitions",
    o.output_edges AS "OUTPUT Edges (transition → material)",
    o.output_transitions AS "OUTPUT Transitions",
    o.output_materials AS "OUTPUT Materials"
FROM lineage_stats i, lineage_outputs o;

\echo ''
\echo 'Expected: INPUT transitions ≈ OUTPUT transitions (same transition set)'
\echo 'Expected: INPUT materials + OUTPUT materials ≈ Total goo.uid count'
\echo ''
\echo '========================================'
\echo ''
\echo 'Checksum validation complete.'
\echo 'Manual comparison with SQL Server required.'
\echo ''
\echo 'Next steps:'
\echo '  1. Run equivalent queries on SQL Server'
\echo '  2. Compare aggregate checksums'
\echo '  3. Investigate any mismatches'
\echo '  4. Document findings in tracking/activity-log-*.md'
\echo '========================================'
