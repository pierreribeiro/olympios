-- ============================================================================
-- SQL Server Data Extraction Script - Tier 2 - PRODUCTION-SAFE
-- Perseus Database Migration: TOP 5000 Sample Extraction with FK Filtering
-- ============================================================================
-- Purpose: Extract TOP 5000 sample from 11 Tier 2 tables (depend on Tier 0-1)
-- Prerequisites: extract-tier0.sql AND extract-tier1.sql
-- Output: Global temp tables for downstream tier extraction + CSV exports
-- Version: 5.0 (TOP 5000 + ORDER BY for deterministic sampling)
-- ============================================================================

USE perseus;
GO

SET NOCOUNT ON;

-- Note: Session ID and tempdb checks performed in Tier 0
-- Variables @session_id and @tempdb_free_mb already declared in concatenated session

PRINT '========================================';
PRINT 'TIER 2 EXTRACTION - Starting (PRODUCTION-SAFE)';
PRINT 'Sample Size: TOP 5000 rows per table (deterministic ORDER BY)';
PRINT 'Tables: 11 tables (depend on Tier 0-1)';
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
IF OBJECT_ID('tempdb..##perseus_tier_1_perseus_user') IS NULL
   OR OBJECT_ID('tempdb..##perseus_tier_1_workflow') IS NULL
   OR OBJECT_ID('tempdb..##perseus_tier_0_goo_type') IS NULL
BEGIN
    PRINT 'ERROR: Tier 1 temp tables not found!';
    PRINT 'You must run extract-tier0.sql and extract-tier1.sql first.';
    RAISERROR('Missing Tier 1 data', 16, 1);
    RETURN;
END
PRINT 'Prerequisite check: PASSED (Tier 0-1 temp tables found)';
PRINT '';

-- ============================================================================
-- TIER 2: TABLES WITH TIER 0-1 DEPENDENCIES
-- CRITICAL FIX: workflow_step uses scope_id → workflow.id (NOT workflow_section_id)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. feed_type
-- Dependencies: perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: feed_type';

    IF OBJECT_ID('tempdb..##perseus_tier_2_feed_type') IS NOT NULL
        DROP TABLE ##perseus_tier_2_feed_type;

    WITH valid_users AS (
        SELECT id FROM ##perseus_tier_1_perseus_user
    )
    SELECT TOP 5000 ft.*
    INTO ##perseus_tier_2_feed_type
    FROM dbo.feed_type ft WITH (NOLOCK)
    WHERE ft.added_by IN (SELECT id FROM valid_users)
    ORDER BY ft.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: feed_type';
END CATCH;

-- ----------------------------------------------------------------------------
-- 2. goo_type_combine_component
-- Dependencies: goo_type_combine_target
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: goo_type_combine_component';

    IF OBJECT_ID('tempdb..##perseus_tier_2_goo_type_combine_component') IS NOT NULL
        DROP TABLE ##perseus_tier_2_goo_type_combine_component;

    WITH valid_targets AS (
        SELECT id FROM ##perseus_tier_1_goo_type_combine_target
    )
    SELECT TOP 5000 gtcc.*
    INTO ##perseus_tier_2_goo_type_combine_component
    FROM dbo.goo_type_combine_component gtcc WITH (NOLOCK)
    WHERE gtcc.goo_type_combine_target_id IN (SELECT id FROM valid_targets)
    ORDER BY gtcc.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: goo_type_combine_component';
END CATCH;

-- ----------------------------------------------------------------------------
-- 3. material_inventory_threshold
-- Dependencies: goo_type, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: material_inventory_threshold';

    IF OBJECT_ID('tempdb..##perseus_tier_2_material_inventory_threshold') IS NOT NULL
        DROP TABLE ##perseus_tier_2_material_inventory_threshold;

    WITH valid_goo_types AS (
        SELECT id FROM ##perseus_tier_0_goo_type
    ),
    valid_users AS (
        SELECT id FROM ##perseus_tier_1_perseus_user
    )
    SELECT TOP 5000 mit.*
    INTO ##perseus_tier_2_material_inventory_threshold
    FROM dbo.material_inventory_threshold mit WITH (NOLOCK)
    WHERE mit.material_type_id IN (SELECT id FROM valid_goo_types)
      AND mit.created_by_id IN (SELECT id FROM valid_users)
    ORDER BY mit.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: material_inventory_threshold';
END CATCH;

-- ----------------------------------------------------------------------------
-- 4. material_inventory_threshold_notify_user
-- Dependencies: material_inventory_threshold, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: material_inventory_threshold_notify_user';

    IF OBJECT_ID('tempdb..##perseus_tier_2_material_inventory_threshold_notify_user') IS NOT NULL
        DROP TABLE ##perseus_tier_2_material_inventory_threshold_notify_user;

    WITH valid_thresholds AS (
        SELECT id FROM ##perseus_tier_2_material_inventory_threshold
    ),
    valid_users AS (
        SELECT id FROM ##perseus_tier_1_perseus_user
    )
    SELECT TOP 5000 mitnu.*
    INTO ##perseus_tier_2_material_inventory_threshold_notify_user
    FROM dbo.material_inventory_threshold_notify_user mitnu WITH (NOLOCK)
    WHERE mitnu.threshold_id IN (SELECT id FROM valid_thresholds)
      AND mitnu.user_id IN (SELECT id FROM valid_users)
    ORDER BY mitnu.threshold_id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: material_inventory_threshold_notify_user';
END CATCH;

-- ----------------------------------------------------------------------------
-- 5. workflow_section
-- Dependencies: workflow
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: workflow_section';

    IF OBJECT_ID('tempdb..##perseus_tier_2_workflow_section') IS NOT NULL
        DROP TABLE ##perseus_tier_2_workflow_section;

    WITH valid_workflows AS (
        SELECT id FROM ##perseus_tier_1_workflow
    )
    SELECT TOP 5000 ws.*
    INTO ##perseus_tier_2_workflow_section
    FROM dbo.workflow_section ws WITH (NOLOCK)
    WHERE ws.workflow_id IN (SELECT id FROM valid_workflows)
    ORDER BY ws.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: workflow_section';
END CATCH;

-- ----------------------------------------------------------------------------
-- 6. workflow_attachment
-- Dependencies: workflow
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: workflow_attachment';

    IF OBJECT_ID('tempdb..##perseus_tier_2_workflow_attachment') IS NOT NULL
        DROP TABLE ##perseus_tier_2_workflow_attachment;

    WITH valid_workflows AS (
        SELECT id FROM ##perseus_tier_1_workflow
    )
    SELECT TOP 5000 wa.*
    INTO ##perseus_tier_2_workflow_attachment
    FROM dbo.workflow_attachment wa WITH (NOLOCK)
    WHERE wa.workflow_id IN (SELECT id FROM valid_workflows)
    ORDER BY wa.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: workflow_attachment';
END CATCH;

-- ----------------------------------------------------------------------------
-- 7. workflow_step - CRITICAL FIX APPLIED
-- Dependencies: workflow (scope_id), goo_type (nullable)
-- CORRECTED: Uses scope_id → workflow.id (NOT workflow_section_id!)
-- CORRECTED: Uses AND logic with OR for nullable goo_type_id
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: workflow_step (CRITICAL FIX APPLIED)';

    IF OBJECT_ID('tempdb..##perseus_tier_2_workflow_step') IS NOT NULL
        DROP TABLE ##perseus_tier_2_workflow_step;

    WITH valid_workflows AS (
        SELECT id FROM ##perseus_tier_1_workflow
    ),
    valid_goo_types AS (
        SELECT id FROM ##perseus_tier_0_goo_type
    )
    SELECT TOP 5000 wstep.*
    INTO ##perseus_tier_2_workflow_step
    FROM dbo.workflow_step wstep WITH (NOLOCK)
    WHERE wstep.scope_id IN (SELECT id FROM valid_workflows)  -- FIXED: scope_id → workflow
      AND (wstep.goo_type_id IN (SELECT id FROM valid_goo_types)
           OR wstep.goo_type_id IS NULL)  -- FIXED: AND with OR for nullable FK
    ORDER BY wstep.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
    PRINT '  ** CRITICAL FIX: scope_id → workflow.id (not workflow_section_id)';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: workflow_step';
END CATCH;

-- ----------------------------------------------------------------------------
-- 8. recipe
-- Dependencies: goo_type, workflow (nullable), feed_type (nullable), perseus_user
-- CORRECTED: Removed non-existent recipe_type_id and recipe_category_id columns
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: recipe';

    IF OBJECT_ID('tempdb..##perseus_tier_2_recipe') IS NOT NULL
        DROP TABLE ##perseus_tier_2_recipe;

    WITH valid_goo_types AS (
        SELECT id FROM ##perseus_tier_0_goo_type
    ),
    valid_workflows AS (
        SELECT id FROM ##perseus_tier_1_workflow
    ),
    valid_feed_types AS (
        SELECT id FROM ##perseus_tier_2_feed_type
    ),
    valid_users AS (
        SELECT id FROM ##perseus_tier_1_perseus_user
    )
    SELECT TOP 5000 r.*
    INTO ##perseus_tier_2_recipe
    FROM dbo.recipe r WITH (NOLOCK)
    WHERE r.goo_type_id IN (SELECT id FROM valid_goo_types)
      AND (r.workflow_id IN (SELECT id FROM valid_workflows) OR r.workflow_id IS NULL)
      AND (r.feed_type_id IN (SELECT id FROM valid_feed_types) OR r.feed_type_id IS NULL)
      AND r.added_by IN (SELECT id FROM valid_users)
    ORDER BY r.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
    PRINT '  ** FIX APPLIED: Removed invalid recipe_type_id/recipe_category_id filters';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: recipe';
END CATCH;

-- ----------------------------------------------------------------------------
-- 9. smurf_group
-- Dependencies: perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: smurf_group';

    IF OBJECT_ID('tempdb..##perseus_tier_2_smurf_group') IS NOT NULL
        DROP TABLE ##perseus_tier_2_smurf_group;

    WITH valid_users AS (
        SELECT id FROM ##perseus_tier_1_perseus_user
    )
    SELECT TOP 5000 sg.*
    INTO ##perseus_tier_2_smurf_group
    FROM dbo.smurf_group sg WITH (NOLOCK)
    WHERE sg.added_by IN (SELECT id FROM valid_users)
    ORDER BY sg.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: smurf_group';
END CATCH;

-- ----------------------------------------------------------------------------
-- 10. smurf_goo_type
-- Dependencies: goo_type
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: smurf_goo_type';

    IF OBJECT_ID('tempdb..##perseus_tier_2_smurf_goo_type') IS NOT NULL
        DROP TABLE ##perseus_tier_2_smurf_goo_type;

    WITH valid_goo_types AS (
        SELECT id FROM ##perseus_tier_0_goo_type
    )
    SELECT TOP 5000 sgt.*
    INTO ##perseus_tier_2_smurf_goo_type
    FROM dbo.smurf_goo_type sgt WITH (NOLOCK)
    WHERE sgt.goo_type_id IN (SELECT id FROM valid_goo_types)
    ORDER BY sgt.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: smurf_goo_type';
END CATCH;

-- ----------------------------------------------------------------------------
-- 11. property_option
-- Dependencies: property
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: property_option';

    IF OBJECT_ID('tempdb..##perseus_tier_2_property_option') IS NOT NULL
        DROP TABLE ##perseus_tier_2_property_option;

    WITH valid_properties AS (
        SELECT id FROM ##perseus_tier_1_property
    )
    SELECT TOP 5000 po.*
    INTO ##perseus_tier_2_property_option
    FROM dbo.property_option po WITH (NOLOCK)
    WHERE po.property_id IN (SELECT id FROM valid_properties)
    ORDER BY po.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: property_option';
END CATCH;

-- ============================================================================
-- EXTRACTION SUMMARY
-- ============================================================================
PRINT '';
PRINT '========================================';
PRINT 'TIER 2 EXTRACTION - Complete';
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
PRINT '  - Deterministic TOP 5000 + ORDER BY sampling';
PRINT '';
PRINT 'CRITICAL CORRECTIONS APPLIED:';
PRINT '  - workflow_step: scope_id → workflow.id (NOT workflow_section_id)';
PRINT '  - workflow_step: AND logic with OR for nullable goo_type_id';
PRINT '';
PRINT 'Next: Run extract-tier3.sql';
PRINT '========================================';
GO

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 1. Global temp tables (##perseus_tier_2_*) persist across sessions
-- 2. CRITICAL FIX: workflow_step.scope_id → workflow.id (not workflow_section_id)
-- 3. Complex FK dependencies use AND logic with OR for nullable FKs
-- 4. NULL FK values are properly handled (optional relationships)
-- 5. Script is IDEMPOTENT - can re-run if failures occur
-- 6. Error handling allows partial extraction to continue
-- 7. PRODUCTION-SAFE: NOLOCK + deterministic sampling + tempdb checks
-- 8. Tables created: 11 (feed_type, goo_type_combine_component,
--    material_inventory_threshold, material_inventory_threshold_notify_user,
--    workflow_section, workflow_attachment, workflow_step, recipe,
--    smurf_group, smurf_goo_type, property_option)
-- ============================================================================
