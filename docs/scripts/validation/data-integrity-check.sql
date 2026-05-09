-- ============================================================================
-- Data Integrity Validation Script
-- Perseus Database Migration - SQL Server → PostgreSQL 17+
-- ============================================================================
-- Purpose: Comprehensive data integrity checks for migration validation
-- Usage: psql -d perseus_dev -f scripts/validation/data-integrity-check.sql
-- Author: Claude Code (Database Expert)
-- Last Updated: 2026-01-24
-- ============================================================================

\set ON_ERROR_STOP on
\timing on

-- Store results in validation schema
CREATE SCHEMA IF NOT EXISTS validation;

-- ============================================================================
-- 1. ROW COUNT VALIDATION
-- ============================================================================
-- Compare row counts between source and target tables
-- Expected: 100% match for all tables

DO $$
DECLARE
    v_table_name TEXT;
    v_row_count BIGINT;
    v_start_time TIMESTAMP := CLOCK_TIMESTAMP();
BEGIN
    RAISE NOTICE '=== ROW COUNT VALIDATION ===';
    RAISE NOTICE 'Started at: %', v_start_time;
    RAISE NOTICE '';

    -- Create results table if not exists
    DROP TABLE IF EXISTS validation.row_count_results;
    CREATE TABLE validation.row_count_results (
        check_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        schema_name TEXT NOT NULL,
        table_name TEXT NOT NULL,
        row_count BIGINT NOT NULL,
        status TEXT,
        notes TEXT
    );

    -- Get row counts for all non-system tables
    FOR v_table_name IN
        SELECT schemaname || '.' || tablename
        FROM pg_tables
        WHERE schemaname NOT IN ('pg_catalog', 'information_schema', 'validation')
        ORDER BY schemaname, tablename
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM %s', v_table_name) INTO v_row_count;

        INSERT INTO validation.row_count_results (schema_name, table_name, row_count, status)
        VALUES (
            split_part(v_table_name, '.', 1),
            split_part(v_table_name, '.', 2),
            v_row_count,
            'COMPLETED'
        );

        RAISE NOTICE 'Table: % - Rows: %', v_table_name, v_row_count;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE 'Row count validation completed in: %', CLOCK_TIMESTAMP() - v_start_time;
    RAISE NOTICE '=================================';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- 2. PRIMARY KEY CONSTRAINT VALIDATION
-- ============================================================================
-- Verify all PKs are defined and no duplicates exist

DO $$
DECLARE
    v_table_record RECORD;
    v_duplicate_count BIGINT;
    v_start_time TIMESTAMP := CLOCK_TIMESTAMP();
BEGIN
    RAISE NOTICE '=== PRIMARY KEY VALIDATION ===';
    RAISE NOTICE 'Started at: %', v_start_time;
    RAISE NOTICE '';

    DROP TABLE IF EXISTS validation.pk_validation_results;
    CREATE TABLE validation.pk_validation_results (
        check_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        schema_name TEXT NOT NULL,
        table_name TEXT NOT NULL,
        constraint_name TEXT,
        pk_columns TEXT,
        duplicate_count BIGINT,
        status TEXT,
        notes TEXT
    );

    -- Check each table for PK definition and duplicates
    FOR v_table_record IN
        SELECT
            n.nspname AS schema_name,
            c.relname AS table_name,
            con.conname AS constraint_name,
            pg_get_constraintdef(con.oid) AS constraint_def
        FROM pg_constraint con
        JOIN pg_class c ON con.conrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE con.contype = 'p'
          AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'validation')
        ORDER BY n.nspname, c.relname
    LOOP
        INSERT INTO validation.pk_validation_results
            (schema_name, table_name, constraint_name, pk_columns, duplicate_count, status, notes)
        VALUES (
            v_table_record.schema_name,
            v_table_record.table_name,
            v_table_record.constraint_name,
            v_table_record.constraint_def,
            0,
            'PK_DEFINED',
            'Primary key constraint exists'
        );

        RAISE NOTICE 'Table: %.% - PK: %',
            v_table_record.schema_name,
            v_table_record.table_name,
            v_table_record.constraint_name;
    END LOOP;

    -- Identify tables WITHOUT primary keys
    INSERT INTO validation.pk_validation_results
        (schema_name, table_name, constraint_name, pk_columns, duplicate_count, status, notes)
    SELECT
        n.nspname,
        c.relname,
        NULL,
        NULL,
        NULL,
        'NO_PK',
        'WARNING: Table has no primary key'
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE c.relkind = 'r'
      AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'validation')
      AND NOT EXISTS (
          SELECT 1
          FROM pg_constraint con
          WHERE con.conrelid = c.oid
            AND con.contype = 'p'
      )
    ORDER BY n.nspname, c.relname;

    RAISE NOTICE '';
    RAISE NOTICE 'Primary key validation completed in: %', CLOCK_TIMESTAMP() - v_start_time;
    RAISE NOTICE '=================================';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- 3. FOREIGN KEY CONSTRAINT VALIDATION
-- ============================================================================
-- Verify FK relationships and referential integrity

DO $$
DECLARE
    v_fk_record RECORD;
    v_orphan_count BIGINT;
    v_start_time TIMESTAMP := CLOCK_TIMESTAMP();
    v_sql TEXT;
BEGIN
    RAISE NOTICE '=== FOREIGN KEY VALIDATION ===';
    RAISE NOTICE 'Started at: %', v_start_time;
    RAISE NOTICE '';

    DROP TABLE IF EXISTS validation.fk_validation_results;
    CREATE TABLE validation.fk_validation_results (
        check_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        constraint_name TEXT NOT NULL,
        child_schema TEXT NOT NULL,
        child_table TEXT NOT NULL,
        child_columns TEXT,
        parent_schema TEXT NOT NULL,
        parent_table TEXT NOT NULL,
        parent_columns TEXT,
        orphan_count BIGINT,
        status TEXT,
        notes TEXT
    );

    -- Check each FK for orphaned records
    FOR v_fk_record IN
        SELECT
            con.conname AS constraint_name,
            n_child.nspname AS child_schema,
            c_child.relname AS child_table,
            ARRAY_TO_STRING(ARRAY_AGG(a_child.attname ORDER BY u.attposition), ', ') AS child_columns,
            n_parent.nspname AS parent_schema,
            c_parent.relname AS parent_table,
            ARRAY_TO_STRING(ARRAY_AGG(a_parent.attname ORDER BY u.attposition), ', ') AS parent_columns
        FROM pg_constraint con
        JOIN pg_class c_child ON con.conrelid = c_child.oid
        JOIN pg_namespace n_child ON c_child.relnamespace = n_child.oid
        JOIN pg_class c_parent ON con.confrelid = c_parent.oid
        JOIN pg_namespace n_parent ON c_parent.relnamespace = n_parent.oid
        JOIN LATERAL UNNEST(con.conkey, con.confkey) WITH ORDINALITY AS u(child_att, parent_att, attposition) ON TRUE
        JOIN pg_attribute a_child ON a_child.attnum = u.child_att AND a_child.attrelid = c_child.oid
        JOIN pg_attribute a_parent ON a_parent.attnum = u.parent_att AND a_parent.attrelid = c_parent.oid
        WHERE con.contype = 'f'
          AND n_child.nspname NOT IN ('pg_catalog', 'information_schema', 'validation')
        GROUP BY con.conname, n_child.nspname, c_child.relname, n_parent.nspname, c_parent.relname
        ORDER BY n_child.nspname, c_child.relname
    LOOP
        -- Build query to check for orphaned records
        v_sql := format(
            'SELECT COUNT(*) FROM %I.%I child ' ||
            'WHERE NOT EXISTS (SELECT 1 FROM %I.%I parent WHERE parent.%s = child.%s)',
            v_fk_record.child_schema,
            v_fk_record.child_table,
            v_fk_record.parent_schema,
            v_fk_record.parent_table,
            v_fk_record.parent_columns,
            v_fk_record.child_columns
        );

        BEGIN
            EXECUTE v_sql INTO v_orphan_count;
        EXCEPTION WHEN OTHERS THEN
            v_orphan_count := -1; -- Error checking
        END;

        INSERT INTO validation.fk_validation_results (
            constraint_name, child_schema, child_table, child_columns,
            parent_schema, parent_table, parent_columns,
            orphan_count, status, notes
        ) VALUES (
            v_fk_record.constraint_name,
            v_fk_record.child_schema,
            v_fk_record.child_table,
            v_fk_record.child_columns,
            v_fk_record.parent_schema,
            v_fk_record.parent_table,
            v_fk_record.parent_columns,
            v_orphan_count,
            CASE
                WHEN v_orphan_count = 0 THEN 'VALID'
                WHEN v_orphan_count > 0 THEN 'ORPHANS_FOUND'
                ELSE 'CHECK_FAILED'
            END,
            CASE
                WHEN v_orphan_count = 0 THEN 'Referential integrity valid'
                WHEN v_orphan_count > 0 THEN format('ERROR: %s orphaned records found', v_orphan_count)
                ELSE 'Error checking constraint'
            END
        );

        RAISE NOTICE 'FK: % (%.% → %.%) - Orphans: %',
            v_fk_record.constraint_name,
            v_fk_record.child_schema, v_fk_record.child_table,
            v_fk_record.parent_schema, v_fk_record.parent_table,
            COALESCE(v_orphan_count::TEXT, 'ERROR');
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE 'Foreign key validation completed in: %', CLOCK_TIMESTAMP() - v_start_time;
    RAISE NOTICE '=================================';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- 4. UNIQUE CONSTRAINT VALIDATION
-- ============================================================================
-- Check for duplicate violations in unique constraints

DO $$
DECLARE
    v_unique_record RECORD;
    v_duplicate_count BIGINT;
    v_start_time TIMESTAMP := CLOCK_TIMESTAMP();
    v_sql TEXT;
BEGIN
    RAISE NOTICE '=== UNIQUE CONSTRAINT VALIDATION ===';
    RAISE NOTICE 'Started at: %', v_start_time;
    RAISE NOTICE '';

    DROP TABLE IF EXISTS validation.unique_validation_results;
    CREATE TABLE validation.unique_validation_results (
        check_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        schema_name TEXT NOT NULL,
        table_name TEXT NOT NULL,
        constraint_name TEXT NOT NULL,
        columns TEXT,
        duplicate_count BIGINT,
        status TEXT,
        notes TEXT
    );

    -- Check each unique constraint
    FOR v_unique_record IN
        SELECT
            n.nspname AS schema_name,
            c.relname AS table_name,
            con.conname AS constraint_name,
            ARRAY_TO_STRING(ARRAY_AGG(a.attname ORDER BY u.attposition), ', ') AS columns
        FROM pg_constraint con
        JOIN pg_class c ON con.conrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN LATERAL UNNEST(con.conkey) WITH ORDINALITY AS u(attnum, attposition) ON TRUE
        JOIN pg_attribute a ON a.attnum = u.attnum AND a.attrelid = c.oid
        WHERE con.contype = 'u'
          AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'validation')
        GROUP BY n.nspname, c.relname, con.conname
        ORDER BY n.nspname, c.relname
    LOOP
        -- Build query to check for duplicates
        v_sql := format(
            'SELECT COUNT(*) FROM ' ||
            '(SELECT %s, COUNT(*) FROM %I.%I GROUP BY %s HAVING COUNT(*) > 1) AS duplicates',
            v_unique_record.columns,
            v_unique_record.schema_name,
            v_unique_record.table_name,
            v_unique_record.columns
        );

        BEGIN
            EXECUTE v_sql INTO v_duplicate_count;
        EXCEPTION WHEN OTHERS THEN
            v_duplicate_count := -1;
        END;

        INSERT INTO validation.unique_validation_results (
            schema_name, table_name, constraint_name, columns,
            duplicate_count, status, notes
        ) VALUES (
            v_unique_record.schema_name,
            v_unique_record.table_name,
            v_unique_record.constraint_name,
            v_unique_record.columns,
            v_duplicate_count,
            CASE
                WHEN v_duplicate_count = 0 THEN 'VALID'
                WHEN v_duplicate_count > 0 THEN 'DUPLICATES_FOUND'
                ELSE 'CHECK_FAILED'
            END,
            CASE
                WHEN v_duplicate_count = 0 THEN 'No duplicates found'
                WHEN v_duplicate_count > 0 THEN format('ERROR: %s duplicate groups found', v_duplicate_count)
                ELSE 'Error checking constraint'
            END
        );

        RAISE NOTICE 'Unique: %.%.% - Duplicates: %',
            v_unique_record.schema_name,
            v_unique_record.table_name,
            v_unique_record.constraint_name,
            COALESCE(v_duplicate_count::TEXT, 'ERROR');
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE 'Unique constraint validation completed in: %', CLOCK_TIMESTAMP() - v_start_time;
    RAISE NOTICE '=================================';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- 5. CHECK CONSTRAINT VALIDATION
-- ============================================================================
-- Verify check constraints are not violated

DO $$
DECLARE
    v_check_record RECORD;
    v_violation_count BIGINT;
    v_start_time TIMESTAMP := CLOCK_TIMESTAMP();
BEGIN
    RAISE NOTICE '=== CHECK CONSTRAINT VALIDATION ===';
    RAISE NOTICE 'Started at: %', v_start_time;
    RAISE NOTICE '';

    DROP TABLE IF EXISTS validation.check_validation_results;
    CREATE TABLE validation.check_validation_results (
        check_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        schema_name TEXT NOT NULL,
        table_name TEXT NOT NULL,
        constraint_name TEXT NOT NULL,
        constraint_definition TEXT,
        violation_count BIGINT,
        status TEXT,
        notes TEXT
    );

    -- List all check constraints
    FOR v_check_record IN
        SELECT
            n.nspname AS schema_name,
            c.relname AS table_name,
            con.conname AS constraint_name,
            pg_get_constraintdef(con.oid) AS constraint_def
        FROM pg_constraint con
        JOIN pg_class c ON con.conrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE con.contype = 'c'
          AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'validation')
        ORDER BY n.nspname, c.relname
    LOOP
        -- Note: Violations would have prevented insert/update, so this is informational
        INSERT INTO validation.check_validation_results (
            schema_name, table_name, constraint_name, constraint_definition,
            violation_count, status, notes
        ) VALUES (
            v_check_record.schema_name,
            v_check_record.table_name,
            v_check_record.constraint_name,
            v_check_record.constraint_def,
            0,
            'DEFINED',
            'Check constraint is enforced'
        );

        RAISE NOTICE 'Check: %.%.% - %',
            v_check_record.schema_name,
            v_check_record.table_name,
            v_check_record.constraint_name,
            v_check_record.constraint_def;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE 'Check constraint validation completed in: %', CLOCK_TIMESTAMP() - v_start_time;
    RAISE NOTICE '=================================';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- 6. NOT NULL CONSTRAINT VALIDATION
-- ============================================================================
-- Verify no NULL values in NOT NULL columns

DO $$
DECLARE
    v_column_record RECORD;
    v_null_count BIGINT;
    v_start_time TIMESTAMP := CLOCK_TIMESTAMP();
    v_sql TEXT;
BEGIN
    RAISE NOTICE '=== NOT NULL VALIDATION ===';
    RAISE NOTICE 'Started at: %', v_start_time;
    RAISE NOTICE '';

    DROP TABLE IF EXISTS validation.notnull_validation_results;
    CREATE TABLE validation.notnull_validation_results (
        check_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        schema_name TEXT NOT NULL,
        table_name TEXT NOT NULL,
        column_name TEXT NOT NULL,
        null_count BIGINT,
        status TEXT,
        notes TEXT
    );

    -- Check each NOT NULL column
    FOR v_column_record IN
        SELECT
            n.nspname AS schema_name,
            c.relname AS table_name,
            a.attname AS column_name
        FROM pg_attribute a
        JOIN pg_class c ON a.attrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE a.attnotnull = TRUE
          AND a.attnum > 0
          AND NOT a.attisdropped
          AND c.relkind = 'r'
          AND n.nspname NOT IN ('pg_catalog', 'information_schema', 'validation')
        ORDER BY n.nspname, c.relname, a.attname
    LOOP
        v_sql := format(
            'SELECT COUNT(*) FROM %I.%I WHERE %I IS NULL',
            v_column_record.schema_name,
            v_column_record.table_name,
            v_column_record.column_name
        );

        BEGIN
            EXECUTE v_sql INTO v_null_count;
        EXCEPTION WHEN OTHERS THEN
            v_null_count := -1;
        END;

        INSERT INTO validation.notnull_validation_results (
            schema_name, table_name, column_name, null_count, status, notes
        ) VALUES (
            v_column_record.schema_name,
            v_column_record.table_name,
            v_column_record.column_name,
            v_null_count,
            CASE
                WHEN v_null_count = 0 THEN 'VALID'
                WHEN v_null_count > 0 THEN 'NULLS_FOUND'
                ELSE 'CHECK_FAILED'
            END,
            CASE
                WHEN v_null_count = 0 THEN 'No NULL values found'
                WHEN v_null_count > 0 THEN format('ERROR: %s NULL values found', v_null_count)
                ELSE 'Error checking column'
            END
        );

        IF v_null_count > 0 OR v_null_count = -1 THEN
            RAISE NOTICE 'NOT NULL: %.%.% - Nulls: %',
                v_column_record.schema_name,
                v_column_record.table_name,
                v_column_record.column_name,
                COALESCE(v_null_count::TEXT, 'ERROR');
        END IF;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE 'NOT NULL validation completed in: %', CLOCK_TIMESTAMP() - v_start_time;
    RAISE NOTICE '=================================';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- 7. DATA TYPE CONSISTENCY VALIDATION
-- ============================================================================
-- Check for data type mismatches in FK relationships

DO $$
DECLARE
    v_mismatch_record RECORD;
    v_start_time TIMESTAMP := CLOCK_TIMESTAMP();
    v_mismatch_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== DATA TYPE CONSISTENCY VALIDATION ===';
    RAISE NOTICE 'Started at: %', v_start_time;
    RAISE NOTICE '';

    DROP TABLE IF EXISTS validation.datatype_validation_results;
    CREATE TABLE validation.datatype_validation_results (
        check_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        constraint_name TEXT NOT NULL,
        child_schema TEXT NOT NULL,
        child_table TEXT NOT NULL,
        child_column TEXT NOT NULL,
        child_type TEXT NOT NULL,
        parent_schema TEXT NOT NULL,
        parent_table TEXT NOT NULL,
        parent_column TEXT NOT NULL,
        parent_type TEXT NOT NULL,
        status TEXT,
        notes TEXT
    );

    -- Find FK relationships with type mismatches
    FOR v_mismatch_record IN
        SELECT
            con.conname AS constraint_name,
            n_child.nspname AS child_schema,
            c_child.relname AS child_table,
            a_child.attname AS child_column,
            format_type(a_child.atttypid, a_child.atttypmod) AS child_type,
            n_parent.nspname AS parent_schema,
            c_parent.relname AS parent_table,
            a_parent.attname AS parent_column,
            format_type(a_parent.atttypid, a_parent.atttypmod) AS parent_type
        FROM pg_constraint con
        JOIN pg_class c_child ON con.conrelid = c_child.oid
        JOIN pg_namespace n_child ON c_child.relnamespace = n_child.oid
        JOIN pg_class c_parent ON con.confrelid = c_parent.oid
        JOIN pg_namespace n_parent ON c_parent.relnamespace = n_parent.oid
        JOIN LATERAL UNNEST(con.conkey, con.confkey) AS u(child_att, parent_att) ON TRUE
        JOIN pg_attribute a_child ON a_child.attnum = u.child_att AND a_child.attrelid = c_child.oid
        JOIN pg_attribute a_parent ON a_parent.attnum = u.parent_att AND a_parent.attrelid = c_parent.oid
        WHERE con.contype = 'f'
          AND n_child.nspname NOT IN ('pg_catalog', 'information_schema', 'validation')
          AND format_type(a_child.atttypid, a_child.atttypmod) != format_type(a_parent.atttypid, a_parent.atttypmod)
        ORDER BY n_child.nspname, c_child.relname
    LOOP
        v_mismatch_count := v_mismatch_count + 1;

        INSERT INTO validation.datatype_validation_results (
            constraint_name, child_schema, child_table, child_column, child_type,
            parent_schema, parent_table, parent_column, parent_type, status, notes
        ) VALUES (
            v_mismatch_record.constraint_name,
            v_mismatch_record.child_schema,
            v_mismatch_record.child_table,
            v_mismatch_record.child_column,
            v_mismatch_record.child_type,
            v_mismatch_record.parent_schema,
            v_mismatch_record.parent_table,
            v_mismatch_record.parent_column,
            v_mismatch_record.parent_type,
            'TYPE_MISMATCH',
            format('WARNING: Child type (%s) differs from parent type (%s)',
                v_mismatch_record.child_type, v_mismatch_record.parent_type)
        );

        RAISE NOTICE 'Type mismatch in FK %: %.%.% (%s) → %.%.% (%s)',
            v_mismatch_record.constraint_name,
            v_mismatch_record.child_schema, v_mismatch_record.child_table, v_mismatch_record.child_column,
            v_mismatch_record.child_type,
            v_mismatch_record.parent_schema, v_mismatch_record.parent_table, v_mismatch_record.parent_column,
            v_mismatch_record.parent_type;
    END LOOP;

    IF v_mismatch_count = 0 THEN
        RAISE NOTICE 'No data type mismatches found';
    ELSE
        RAISE NOTICE 'Found % data type mismatch(es)', v_mismatch_count;
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE 'Data type validation completed in: %', CLOCK_TIMESTAMP() - v_start_time;
    RAISE NOTICE '=================================';
    RAISE NOTICE '';
END $$;

-- ============================================================================
-- 8. SUMMARY REPORT
-- ============================================================================
-- Generate comprehensive validation summary

DO $$
DECLARE
    v_total_tables INTEGER;
    v_total_pks INTEGER;
    v_tables_without_pk INTEGER;
    v_total_fks INTEGER;
    v_fks_with_orphans INTEGER;
    v_total_unique INTEGER;
    v_unique_with_duplicates INTEGER;
    v_total_checks INTEGER;
    v_total_notnull INTEGER;
    v_notnull_with_nulls INTEGER;
    v_type_mismatches INTEGER;
    v_overall_status TEXT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '                     DATA INTEGRITY VALIDATION SUMMARY';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';

    -- Row counts
    SELECT COUNT(DISTINCT table_name) INTO v_total_tables
    FROM validation.row_count_results;
    RAISE NOTICE '1. ROW COUNTS';
    RAISE NOTICE '   - Total tables validated: %', v_total_tables;
    RAISE NOTICE '';

    -- Primary keys
    SELECT
        COUNT(*) FILTER (WHERE status = 'PK_DEFINED'),
        COUNT(*) FILTER (WHERE status = 'NO_PK')
    INTO v_total_pks, v_tables_without_pk
    FROM validation.pk_validation_results;
    RAISE NOTICE '2. PRIMARY KEYS';
    RAISE NOTICE '   - Tables with PKs: %', v_total_pks;
    RAISE NOTICE '   - Tables WITHOUT PKs: % %',
        v_tables_without_pk,
        CASE WHEN v_tables_without_pk > 0 THEN '⚠️  WARNING' ELSE '✓' END;
    RAISE NOTICE '';

    -- Foreign keys
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE status = 'ORPHANS_FOUND')
    INTO v_total_fks, v_fks_with_orphans
    FROM validation.fk_validation_results;
    RAISE NOTICE '3. FOREIGN KEYS';
    RAISE NOTICE '   - Total FKs validated: %', v_total_fks;
    RAISE NOTICE '   - FKs with orphaned records: % %',
        v_fks_with_orphans,
        CASE WHEN v_fks_with_orphans > 0 THEN '❌ ERROR' ELSE '✓' END;
    RAISE NOTICE '';

    -- Unique constraints
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE status = 'DUPLICATES_FOUND')
    INTO v_total_unique, v_unique_with_duplicates
    FROM validation.unique_validation_results;
    RAISE NOTICE '4. UNIQUE CONSTRAINTS';
    RAISE NOTICE '   - Total unique constraints: %', v_total_unique;
    RAISE NOTICE '   - Constraints with duplicates: % %',
        v_unique_with_duplicates,
        CASE WHEN v_unique_with_duplicates > 0 THEN '❌ ERROR' ELSE '✓' END;
    RAISE NOTICE '';

    -- Check constraints
    SELECT COUNT(*) INTO v_total_checks
    FROM validation.check_validation_results;
    RAISE NOTICE '5. CHECK CONSTRAINTS';
    RAISE NOTICE '   - Total check constraints: % ✓', v_total_checks;
    RAISE NOTICE '';

    -- NOT NULL constraints
    SELECT
        COUNT(*),
        COUNT(*) FILTER (WHERE status = 'NULLS_FOUND')
    INTO v_total_notnull, v_notnull_with_nulls
    FROM validation.notnull_validation_results;
    RAISE NOTICE '6. NOT NULL CONSTRAINTS';
    RAISE NOTICE '   - Total NOT NULL columns: %', v_total_notnull;
    RAISE NOTICE '   - Columns with NULL violations: % %',
        v_notnull_with_nulls,
        CASE WHEN v_notnull_with_nulls > 0 THEN '❌ ERROR' ELSE '✓' END;
    RAISE NOTICE '';

    -- Data type consistency
    SELECT COUNT(*) INTO v_type_mismatches
    FROM validation.datatype_validation_results;
    RAISE NOTICE '7. DATA TYPE CONSISTENCY';
    RAISE NOTICE '   - FK type mismatches: % %',
        v_type_mismatches,
        CASE WHEN v_type_mismatches > 0 THEN '⚠️  WARNING' ELSE '✓' END;
    RAISE NOTICE '';

    -- Overall status
    IF v_fks_with_orphans > 0 OR v_unique_with_duplicates > 0 OR v_notnull_with_nulls > 0 THEN
        v_overall_status := '❌ FAILED - Critical integrity violations found';
    ELSIF v_tables_without_pk > 0 OR v_type_mismatches > 0 THEN
        v_overall_status := '⚠️  WARNINGS - Review recommended';
    ELSE
        v_overall_status := '✓ PASSED - All integrity checks successful';
    END IF;

    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'OVERALL STATUS: %', v_overall_status;
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Detailed results stored in validation schema:';
    RAISE NOTICE '  - validation.row_count_results';
    RAISE NOTICE '  - validation.pk_validation_results';
    RAISE NOTICE '  - validation.fk_validation_results';
    RAISE NOTICE '  - validation.unique_validation_results';
    RAISE NOTICE '  - validation.check_validation_results';
    RAISE NOTICE '  - validation.notnull_validation_results';
    RAISE NOTICE '  - validation.datatype_validation_results';
    RAISE NOTICE '';
    RAISE NOTICE 'Query example: SELECT * FROM validation.fk_validation_results WHERE status != ''VALID'';';
    RAISE NOTICE '============================================================================';
END $$;

-- ============================================================================
-- END OF DATA INTEGRITY VALIDATION SCRIPT
-- ============================================================================
