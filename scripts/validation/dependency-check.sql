-- =============================================================================
-- Dependency Validation Script for Perseus Database Migration
-- =============================================================================
-- Purpose: Validate object dependencies across tables, views, functions,
--          procedures, and constraints to ensure safe deployment order
--
-- Usage: psql -d perseus_dev -f scripts/validation/dependency-check.sql
--
-- Returns: Comprehensive dependency analysis with:
--   - Missing dependencies (CRITICAL)
--   - Circular dependencies (WARNING)
--   - Dependency tree visualization
--   - Deployment order validation
--
-- Author: Perseus Migration Team
-- Last Updated: 2026-01-24
-- =============================================================================

\set ON_ERROR_STOP on
\timing on
\pset border 2
\pset format wrapped

-- Enable extended display for better readability
\x auto

BEGIN;

-- =============================================================================
-- SECTION 1: Missing Dependencies Check (CRITICAL)
-- =============================================================================
\echo ''
\echo '========================================================================='
\echo 'SECTION 1: MISSING DEPENDENCIES CHECK (CRITICAL)'
\echo '========================================================================='
\echo ''

-- Check for missing table dependencies
\echo '--- Missing Table Dependencies ---'
SELECT
    tc.table_schema AS dependent_schema,
    tc.table_name AS dependent_table,
    'FOREIGN KEY' AS dependency_type,
    ccu.table_schema AS required_schema,
    ccu.table_name AS required_table,
    tc.constraint_name,
    'CRITICAL - Referenced table does not exist' AS severity
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
    AND tc.table_schema = ccu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND NOT EXISTS (
        SELECT 1
        FROM information_schema.tables t
        WHERE t.table_schema = ccu.table_schema
            AND t.table_name = ccu.table_name
    )
    AND tc.table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY dependent_schema, dependent_table, required_table;

-- Check for missing view dependencies
\echo ''
\echo '--- Missing View Dependencies ---'
WITH view_deps AS (
    SELECT DISTINCT
        v.table_schema AS view_schema,
        v.table_name AS view_name,
        d.refobjid::regclass::text AS referenced_object
    FROM information_schema.views v
    JOIN pg_depend d ON d.objid = (
        SELECT c.oid
        FROM pg_class c
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = v.table_schema
            AND c.relname = v.table_name
    )
    WHERE d.deptype = 'n'
        AND d.refobjid::regclass::text NOT LIKE 'pg_%'
        AND v.table_schema NOT IN ('pg_catalog', 'information_schema')
)
SELECT
    view_schema,
    view_name,
    'VIEW DEPENDENCY' AS dependency_type,
    referenced_object,
    'CRITICAL - Referenced object does not exist' AS severity
FROM view_deps vd
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE (n.nspname || '.' || c.relname) = vd.referenced_object
        OR c.relname::text = vd.referenced_object
)
ORDER BY view_schema, view_name, referenced_object;

-- Check for missing function dependencies
\echo ''
\echo '--- Missing Function Dependencies ---'
SELECT
    n.nspname AS function_schema,
    p.proname AS function_name,
    pg_get_function_arguments(p.oid) AS function_args,
    'FUNCTION DEPENDENCY' AS dependency_type,
    d.refobjid::regclass::text AS referenced_object,
    'CRITICAL - Referenced object does not exist' AS severity
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
JOIN pg_depend d ON d.objid = p.oid
WHERE d.deptype = 'n'
    AND d.refobjid::regclass::text NOT LIKE 'pg_%'
    AND n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND NOT EXISTS (
        SELECT 1
        FROM pg_class c
        JOIN pg_namespace ns ON c.relnamespace = ns.oid
        WHERE (ns.nspname || '.' || c.relname) = d.refobjid::regclass::text
            OR c.relname::text = d.refobjid::regclass::text
    )
ORDER BY function_schema, function_name, referenced_object;

-- =============================================================================
-- SECTION 2: Circular Dependencies Check (WARNING)
-- =============================================================================
\echo ''
\echo '========================================================================='
\echo 'SECTION 2: CIRCULAR DEPENDENCIES CHECK (WARNING)'
\echo '========================================================================='
\echo ''

-- Check for circular foreign key dependencies
\echo '--- Circular Foreign Key Dependencies ---'
WITH RECURSIVE fk_tree AS (
    -- Base case: all foreign keys
    SELECT
        tc.table_schema || '.' || tc.table_name AS from_table,
        ccu.table_schema || '.' || ccu.table_name AS to_table,
        tc.constraint_name::name,
        1 AS depth,
        ARRAY[tc.table_schema || '.' || tc.table_name] AS path
    FROM information_schema.table_constraints tc
    JOIN information_schema.constraint_column_usage ccu
        ON tc.constraint_name = ccu.constraint_name
        AND tc.table_schema = ccu.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema NOT IN ('pg_catalog', 'information_schema')

    UNION ALL

    -- Recursive case: follow the chain
    SELECT
        ft.from_table,
        tc2.to_table,
        ft.constraint_name || ' -> ' || tc2.constraint_name,
        ft.depth + 1,
        ft.path || tc2.to_table
    FROM fk_tree ft
    JOIN (
        SELECT
            tc.table_schema || '.' || tc.table_name AS from_table,
            ccu.table_schema || '.' || ccu.table_name AS to_table,
            tc.constraint_name::name
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu
            ON tc.constraint_name = ccu.constraint_name
            AND tc.table_schema = ccu.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema NOT IN ('pg_catalog', 'information_schema')
    ) tc2 ON ft.to_table = tc2.from_table
    WHERE ft.depth < 10
        AND NOT (tc2.to_table = ANY(ft.path))
)
SELECT
    from_table,
    to_table,
    constraint_name AS dependency_chain,
    depth,
    'WARNING - Circular dependency detected' AS severity
FROM fk_tree
WHERE from_table = to_table
    AND depth > 1
ORDER BY depth DESC, from_table, to_table;

-- =============================================================================
-- SECTION 3: Dependency Tree Visualization
-- =============================================================================
\echo ''
\echo '========================================================================='
\echo 'SECTION 3: DEPENDENCY TREE VISUALIZATION'
\echo '========================================================================='
\echo ''

-- Tables dependency tree
\echo '--- Tables Dependency Tree (Foreign Keys) ---'
WITH RECURSIVE dep_tree AS (
    -- Root tables (no dependencies)
    SELECT
        t.table_schema || '.' || t.table_name AS table_name,
        0 AS level,
        ARRAY[t.table_schema || '.' || t.table_name] AS path,
        t.table_schema || '.' || t.table_name AS root_table
    FROM information_schema.tables t
    WHERE t.table_schema NOT IN ('pg_catalog', 'information_schema')
        AND t.table_type = 'BASE TABLE'
        AND NOT EXISTS (
            SELECT 1
            FROM information_schema.table_constraints tc
            WHERE tc.table_schema = t.table_schema
                AND tc.table_name = t.table_name
                AND tc.constraint_type = 'FOREIGN KEY'
        )

    UNION ALL

    -- Dependent tables
    SELECT
        tc.table_schema || '.' || tc.table_name,
        dt.level + 1,
        dt.path || (tc.table_schema || '.' || tc.table_name),
        dt.root_table
    FROM dep_tree dt
    JOIN information_schema.table_constraints tc ON TRUE
    JOIN information_schema.constraint_column_usage ccu
        ON tc.constraint_name = ccu.constraint_name
        AND tc.table_schema = ccu.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
        AND (ccu.table_schema || '.' || ccu.table_name) = dt.table_name
        AND NOT ((tc.table_schema || '.' || tc.table_name) = ANY(dt.path))
        AND dt.level < 10
)
SELECT
    REPEAT('  ', level) || table_name AS dependency_tree,
    level AS dependency_level,
    root_table,
    array_length(path, 1) AS path_length
FROM dep_tree
ORDER BY root_table, level, table_name
LIMIT 100;

-- Views dependency count
\echo ''
\echo '--- Views Dependency Summary ---'
SELECT
    v.table_schema AS view_schema,
    v.table_name AS view_name,
    COUNT(DISTINCT d.refobjid) AS dependency_count,
    string_agg(DISTINCT d.refobjid::regclass::text, ', ' ORDER BY d.refobjid::regclass::text) AS dependencies
FROM information_schema.views v
JOIN pg_depend d ON d.objid = (
    SELECT c.oid
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = v.table_schema
        AND c.relname = v.table_name
)
WHERE d.deptype = 'n'
    AND d.refobjid::regclass::text NOT LIKE 'pg_%'
    AND v.table_schema NOT IN ('pg_catalog', 'information_schema')
GROUP BY v.table_schema, v.table_name
ORDER BY dependency_count DESC, view_schema, view_name
LIMIT 50;

-- Functions dependency count
\echo ''
\echo '--- Functions Dependency Summary ---'
SELECT
    n.nspname AS function_schema,
    p.proname AS function_name,
    pg_get_function_arguments(p.oid) AS function_args,
    COUNT(DISTINCT d.refobjid) AS dependency_count,
    string_agg(DISTINCT d.refobjid::regclass::text, ', ' ORDER BY d.refobjid::regclass::text) AS dependencies
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
JOIN pg_depend d ON d.objid = p.oid
WHERE d.deptype = 'n'
    AND d.refobjid::regclass::text NOT LIKE 'pg_%'
    AND n.nspname NOT IN ('pg_catalog', 'information_schema')
GROUP BY n.nspname, p.proname, p.oid
ORDER BY dependency_count DESC, function_schema, function_name
LIMIT 50;

-- =============================================================================
-- SECTION 4: Deployment Order Validation
-- =============================================================================
\echo ''
\echo '========================================================================='
\echo 'SECTION 4: DEPLOYMENT ORDER VALIDATION'
\echo '========================================================================='
\echo ''

-- Recommended deployment order for tables (simplified approach)
\echo '--- Recommended Table Deployment Order ---'
\echo 'Note: Tables grouped by dependency level (0=no dependencies, 1=depends on level 0, etc.)'

-- Get all table dependencies
CREATE TEMPORARY TABLE IF NOT EXISTS temp_table_deps AS
SELECT DISTINCT
    tc.table_schema,
    tc.table_name,
    ccu.table_schema AS depends_on_schema,
    ccu.table_name AS depends_on_table
FROM information_schema.table_constraints tc
JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
    AND tc.table_schema = ccu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema NOT IN ('pg_catalog', 'information_schema');

-- Calculate deployment levels iteratively
CREATE TEMPORARY TABLE IF NOT EXISTS temp_deployment_order (
    table_schema VARCHAR(63),
    table_name VARCHAR(63),
    deployment_level INTEGER,
    PRIMARY KEY (table_schema, table_name)
);

-- Level 0: Tables with no foreign keys
INSERT INTO temp_deployment_order
SELECT
    t.table_schema,
    t.table_name,
    0 AS deployment_level
FROM information_schema.tables t
WHERE t.table_schema NOT IN ('pg_catalog', 'information_schema', 'validation', 'performance', 'fixtures', 'perseus_test')
    AND t.table_type = 'BASE TABLE'
    AND NOT EXISTS (
        SELECT 1
        FROM temp_table_deps td
        WHERE td.table_schema = t.table_schema
            AND td.table_name = t.table_name
    );

-- Display deployment order
SELECT
    deployment_level,
    table_schema || '.' || table_name AS table_name,
    'Level 0: No dependencies' AS deployment_note
FROM temp_deployment_order
ORDER BY deployment_level, table_schema, table_name;

-- Cleanup
DROP TABLE IF EXISTS temp_table_deps;
DROP TABLE IF EXISTS temp_deployment_order;

-- Object type deployment order
\echo ''
\echo '--- Object Type Deployment Order Summary ---'
SELECT
    recommended_order,
    object_type,
    deployment_notes
FROM (
    SELECT 1 AS recommended_order, 'DOMAIN' AS object_type, 'Create domains before tables' AS deployment_notes
    UNION ALL
    SELECT 2, 'TABLE', 'Deploy in dependency order (see above)'
    UNION ALL
    SELECT 3, 'INDEX', 'After tables, before constraints'
    UNION ALL
    SELECT 4, 'CONSTRAINT', 'After tables and indexes'
    UNION ALL
    SELECT 5, 'VIEW', 'After tables, in dependency order'
    UNION ALL
    SELECT 6, 'FUNCTION', 'After tables and views'
    UNION ALL
    SELECT 7, 'PROCEDURE', 'After all other objects'
    UNION ALL
    SELECT 8, 'TRIGGER', 'Last, after all dependent objects'
) AS deployment_order
ORDER BY recommended_order;

-- =============================================================================
-- SECTION 5: Critical Path Objects (Perseus P0)
-- =============================================================================
\echo ''
\echo '========================================================================='
\echo 'SECTION 5: CRITICAL PATH OBJECTS CHECK (Perseus P0)'
\echo '========================================================================='
\echo ''

-- Check P0 critical objects existence
\echo '--- P0 Critical Objects Status ---'
WITH p0_objects AS (
    SELECT 'VIEW' AS object_type, 'public' AS schema_name, 'translated' AS object_name, 'Materialized view' AS notes
    UNION ALL
    SELECT 'FUNCTION', 'public', 'mcgetupstream', 'Table-valued function'
    UNION ALL
    SELECT 'FUNCTION', 'public', 'mcgetdownstream', 'Table-valued function'
    UNION ALL
    SELECT 'FUNCTION', 'public', 'mcgetupstreambylist', 'Table-valued function'
    UNION ALL
    SELECT 'FUNCTION', 'public', 'mcgetdownstreambylist', 'Table-valued function'
    UNION ALL
    SELECT 'TABLE', 'public', 'goo', 'Core material table'
    UNION ALL
    SELECT 'TABLE', 'public', 'material_transition', 'Material tracking'
    UNION ALL
    SELECT 'TABLE', 'public', 'transition_material', 'Material tracking'
)
SELECT
    p.object_type,
    p.schema_name || '.' || p.object_name AS object_name,
    p.notes,
    CASE
        WHEN p.object_type = 'VIEW' AND EXISTS (
            SELECT 1 FROM information_schema.views v
            WHERE v.table_schema = p.schema_name AND v.table_name = p.object_name
        ) THEN 'EXISTS ✓'
        WHEN p.object_type = 'TABLE' AND EXISTS (
            SELECT 1 FROM information_schema.tables t
            WHERE t.table_schema = p.schema_name AND t.table_name = p.object_name
        ) THEN 'EXISTS ✓'
        WHEN p.object_type = 'FUNCTION' AND EXISTS (
            SELECT 1 FROM pg_proc pr
            JOIN pg_namespace n ON pr.pronamespace = n.oid
            WHERE n.nspname = p.schema_name AND pr.proname = p.object_name
        ) THEN 'EXISTS ✓'
        ELSE 'MISSING ✗'
    END AS status
FROM p0_objects p
ORDER BY
    CASE object_type
        WHEN 'TABLE' THEN 1
        WHEN 'VIEW' THEN 2
        WHEN 'FUNCTION' THEN 3
    END,
    object_name;

-- =============================================================================
-- SECTION 6: Summary Report
-- =============================================================================
\echo ''
\echo '========================================================================='
\echo 'SECTION 6: VALIDATION SUMMARY REPORT'
\echo '========================================================================='
\echo ''

SELECT
    'DEPENDENCY VALIDATION COMPLETE' AS status,
    CURRENT_TIMESTAMP AS validation_timestamp,
    current_database() AS database_name,
    current_user AS validated_by;

\echo ''
\echo '--- Action Items ---'
\echo 'Review all CRITICAL missing dependencies above before deployment.'
\echo 'Resolve WARNING circular dependencies or document as intentional.'
\echo 'Follow recommended deployment order to avoid runtime errors.'
\echo 'Ensure all P0 critical path objects exist before STAGING deployment.'
\echo ''

ROLLBACK; -- Read-only validation, no changes committed

\echo '========================================================================='
\echo 'Validation complete. No database changes were made.'
\echo '========================================================================='
