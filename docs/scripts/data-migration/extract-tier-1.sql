-- ============================================================================
-- SQL Server Data Extraction Script - Tier 1 - PRODUCTION-SAFE
-- Perseus Database Migration: TOP 5000 Sample Extraction with FK Filtering
-- ============================================================================
-- Purpose: Extract TOP 5000 sample from 9 Tier 1 tables (depend only on Tier 0)
-- Prerequisites: extract-tier0.sql MUST be executed first
-- Output: Global temp tables for downstream tier extraction + CSV exports
-- Version: 5.0 (TOP 5000 + ORDER BY: deterministic sampling)
-- ============================================================================

USE perseus;
GO

SET NOCOUNT ON;

-- Note: Session ID and tempdb checks performed in Tier 0
-- Variables @session_id and @tempdb_free_mb already declared in concatenated session

PRINT '========================================';
PRINT 'TIER 1 EXTRACTION - Starting (PRODUCTION-SAFE)';
PRINT 'Sample Rate: TOP 5000 (deterministic ORDER BY id)';
PRINT 'Tables: 9 tables (depend on Tier 0 only)';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- ERROR COUNTERS
-- ============================================================================
DECLARE @total_tables INT = 0;
DECLARE @success_tables INT = 0;
DECLARE @failed_tables INT = 0;
DECLARE @total_rows INT = 0;

-- ============================================================================
-- PREREQUISITE CHECK
-- ============================================================================
IF OBJECT_ID('tempdb..##perseus_tier_0_goo_type') IS NULL
   OR OBJECT_ID('tempdb..##perseus_tier_0_unit') IS NULL
   OR OBJECT_ID('tempdb..##perseus_tier_0_manufacturer') IS NULL
   OR OBJECT_ID('tempdb..##perseus_tier_0_container_type') IS NULL
   OR OBJECT_ID('tempdb..##perseus_tier_0_container') IS NULL
BEGIN
    PRINT 'ERROR: Critical Tier 0 temp tables not found!';
    PRINT 'You must run extract-tier0.sql first in this session.';
    RAISERROR('Missing Tier 0 data', 16, 1);
    RETURN;
END
PRINT 'Prerequisite check: PASSED (Tier 0 temp tables found)';
PRINT '';

-- ============================================================================
-- TIER 1: TABLES WITH TIER 0 DEPENDENCIES ONLY
-- Strategy: Extract TOP 5000 rows using deterministic ORDER BY id
-- CORRECTED ORDER: perseus_user BEFORE workflow (to enable proper FK filtering)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. perseus_user (P0 CRITICAL) - MOVED TO FIRST
-- Dependencies: manufacturer
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: perseus_user (P0 CRITICAL)';

    IF OBJECT_ID('tempdb..##perseus_tier_1_perseus_user') IS NOT NULL
        DROP TABLE ##perseus_tier_1_perseus_user;

    WITH valid_manufacturers AS (
        SELECT id FROM ##perseus_tier_0_manufacturer
    )
    SELECT TOP 5000 pu.*
    INTO ##perseus_tier_1_perseus_user
    FROM dbo.perseus_user pu WITH (NOLOCK)
    WHERE pu.manufacturer_id IN (SELECT id FROM valid_manufacturers)
    ORDER BY pu.id;

    DECLARE @perseus_user_rows INT = @@ROWCOUNT;
    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @perseus_user_rows;
    PRINT '  Rows: ' + CAST(@perseus_user_rows AS VARCHAR(10)) + ' - SUCCESS';

    IF @perseus_user_rows = 0
    BEGIN
        PRINT '  CRITICAL: Zero rows from perseus_user!';
        RAISERROR('P0 CRITICAL: perseus_user extraction failed', 16, 1);
        RETURN;
    END
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  CRITICAL: perseus_user table extraction failed!';
    RAISERROR('P0 CRITICAL table extraction failed', 16, 1);
    RETURN;
END CATCH;

-- ----------------------------------------------------------------------------
-- 2. property
-- Dependencies: unit
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: property';

    IF OBJECT_ID('tempdb..##perseus_tier_1_property') IS NOT NULL
        DROP TABLE ##perseus_tier_1_property;

    WITH valid_fk AS (
        SELECT id FROM ##perseus_tier_0_unit
    )
    SELECT TOP 5000 p.*
    INTO ##perseus_tier_1_property
    FROM dbo.property p WITH (NOLOCK)
    WHERE p.unit_id IN (SELECT id FROM valid_fk)
    ORDER BY p.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: property';
END CATCH;

-- ----------------------------------------------------------------------------
-- 3. robot_log_type
-- Dependencies: container_type
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: robot_log_type';

    IF OBJECT_ID('tempdb..##perseus_tier_1_robot_log_type') IS NOT NULL
        DROP TABLE ##perseus_tier_1_robot_log_type;

    WITH valid_fk AS (
        SELECT id FROM ##perseus_tier_0_container_type
    )
    SELECT TOP 5000 rlt.*
    INTO ##perseus_tier_1_robot_log_type
    FROM dbo.robot_log_type rlt WITH (NOLOCK)
    WHERE rlt.destination_container_type_id IN (SELECT id FROM valid_fk)
    ORDER BY rlt.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: robot_log_type';
END CATCH;

-- ----------------------------------------------------------------------------
-- 4. container_type_position
-- Dependencies: container_type
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: container_type_position';

    IF OBJECT_ID('tempdb..##perseus_tier_1_container_type_position') IS NOT NULL
        DROP TABLE ##perseus_tier_1_container_type_position;

    WITH valid_fk AS (
        SELECT id FROM ##perseus_tier_0_container_type
    )
    SELECT TOP 5000 ctp.*
    INTO ##perseus_tier_1_container_type_position
    FROM dbo.container_type_position ctp WITH (NOLOCK)
    WHERE ctp.parent_container_type_id IN (SELECT id FROM valid_fk)
    ORDER BY ctp.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: container_type_position';
END CATCH;

-- ----------------------------------------------------------------------------
-- 5. goo_type_combine_target
-- Dependencies: goo_type
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: goo_type_combine_target';

    IF OBJECT_ID('tempdb..##perseus_tier_1_goo_type_combine_target') IS NOT NULL
        DROP TABLE ##perseus_tier_1_goo_type_combine_target;

    WITH valid_fk AS (
        SELECT id FROM ##perseus_tier_0_goo_type
    )
    SELECT TOP 5000 gtct.*
    INTO ##perseus_tier_1_goo_type_combine_target
    FROM dbo.goo_type_combine_target gtct WITH (NOLOCK)
    WHERE gtct.goo_type_id IN (SELECT goo_type_id FROM valid_fk)
    ORDER BY gtct.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: goo_type_combine_target';
END CATCH;

-- ----------------------------------------------------------------------------
-- 6. container_history
-- Dependencies: container
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: container_history';

    IF OBJECT_ID('tempdb..##perseus_tier_1_container_history') IS NOT NULL
        DROP TABLE ##perseus_tier_1_container_history;

    WITH valid_fk AS (
        SELECT id FROM ##perseus_tier_0_container
    )
    SELECT TOP 5000 ch.*
    INTO ##perseus_tier_1_container_history
    FROM dbo.container_history ch WITH (NOLOCK)
    WHERE ch.container_id IN (SELECT container_id FROM valid_fk)
    ORDER BY ch.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: container_history';
END CATCH;

-- ----------------------------------------------------------------------------
-- 7. workflow (P1 Critical) - NOW AFTER perseus_user
-- Dependencies: manufacturer, perseus_user (created_by_id)
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: workflow (P1 CRITICAL)';

    IF OBJECT_ID('tempdb..##perseus_tier_1_workflow') IS NOT NULL
        DROP TABLE ##perseus_tier_1_workflow;

    WITH valid_manufacturers AS (
        SELECT id FROM ##perseus_tier_0_manufacturer
    ),
    valid_users AS (
        SELECT id FROM ##perseus_tier_1_perseus_user
    )
    SELECT TOP 5000 w.*
    INTO ##perseus_tier_1_workflow
    FROM dbo.workflow w WITH (NOLOCK)
    WHERE w.manufacturer_id IN (SELECT id FROM valid_manufacturers)
      AND (w.added_by IN (SELECT id FROM valid_users) OR w.added_by IS NULL)
    ORDER BY w.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: workflow';
END CATCH;

-- ----------------------------------------------------------------------------
-- 8. field_map_display_type
-- Dependencies: field_map, display_type
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: field_map_display_type';

    IF OBJECT_ID('tempdb..##perseus_tier_1_field_map_display_type') IS NOT NULL
        DROP TABLE ##perseus_tier_1_field_map_display_type;

    WITH valid_field_maps AS (
        SELECT id FROM ##perseus_tier_0_field_map
    ),
    valid_display_types AS (
        SELECT id FROM ##perseus_tier_0_display_type
    )
    SELECT TOP 5000 fmdt.*
    INTO ##perseus_tier_1_field_map_display_type
    FROM dbo.field_map_display_type fmdt WITH (NOLOCK)
    WHERE fmdt.field_map_id IN (SELECT id FROM valid_field_maps)
      AND fmdt.display_type_id IN (SELECT id FROM valid_display_types)
    ORDER BY fmdt.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: field_map_display_type';
END CATCH;

-- ----------------------------------------------------------------------------
-- 9. field_map_display_type_user
-- Dependencies: field_map_display_type, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: field_map_display_type_user';

    IF OBJECT_ID('tempdb..##perseus_tier_1_field_map_display_type_user') IS NOT NULL
        DROP TABLE ##perseus_tier_1_field_map_display_type_user;

    WITH valid_field_map_display_types AS (
        SELECT id FROM ##perseus_tier_1_field_map_display_type
    ),
    valid_users AS (
        SELECT id FROM ##perseus_tier_1_perseus_user
    )
    SELECT TOP 5000 fmdtu.*
    INTO ##perseus_tier_1_field_map_display_type_user
    FROM dbo.field_map_display_type_user fmdtu WITH (NOLOCK)
    WHERE fmdtu.field_map_display_type_id IN (SELECT id FROM valid_field_map_display_types)
      AND fmdtu.user_id IN (SELECT id FROM valid_users)
    ORDER BY fmdtu.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: field_map_display_type_user';
END CATCH;

-- ============================================================================
-- EXTRACTION SUMMARY
-- ============================================================================
PRINT '';
PRINT '========================================';
PRINT 'TIER 1 EXTRACTION - Complete';
PRINT '========================================';
PRINT 'Total Tables: ' + CAST(@total_tables AS VARCHAR(10));
PRINT 'Success: ' + CAST(@success_tables AS VARCHAR(10));
PRINT 'Failed: ' + CAST(@failed_tables AS VARCHAR(10));
PRINT 'Total Rows: ' + CAST(@total_rows AS VARCHAR(10));

IF @success_tables > 0
    PRINT 'Avg Rows/Table: ' + CAST(@total_rows / @success_tables AS VARCHAR(10));

PRINT '';
PRINT 'PRODUCTION-SAFE FEATURES:';
PRINT '  - Session ID logged for manual intervention';
PRINT '  - Tempdb space validated (2GB minimum)';
PRINT '  - NOLOCK hints applied to all queries';
PRINT '  - Deterministic TOP 5000 + ORDER BY id sampling';
PRINT '';
PRINT 'Next: Run extract-tier2.sql';
PRINT '========================================';
GO

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 1. Global temp tables (##perseus_tier_1_*) persist across sessions
-- 2. FK filtering ensures referential integrity
-- 3. perseus_user extracted FIRST to enable workflow FK filtering
-- 4. TOP 5000 + ORDER BY id ensures deterministic, repeatable sampling
-- 5. Script is IDEMPOTENT - can re-run if failures occur
-- 6. Error handling allows partial extraction to continue
-- 7. PRODUCTION-SAFE: NOLOCK + deterministic TOP 5000 + tempdb checks
-- 8. Tables created: 9 (perseus_user, property, robot_log_type,
--    container_type_position, goo_type_combine_target, container_history,
--    workflow, field_map_display_type, field_map_display_type_user)
-- ============================================================================
