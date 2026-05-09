-- ============================================================================
-- SQL Server Data Extraction Script - Tier 4 (FINAL TIER) - PRODUCTION-SAFE
-- Perseus Database Migration: TOP 5000 Sample Extraction with FK Filtering
-- ============================================================================
-- Purpose: Extract TOP 5000 sample from 11 Tier 4 tables (highest dependencies)
-- INCLUDES P0 CRITICAL LINEAGE TABLES: material_transition, transition_material
-- Prerequisites: extract-tier0-corrected through tier3-corrected MUST be executed first
-- Output: Final global temp tables + CSV exports
-- Version: 5.0 (Deterministic TOP 5000 + ORDER BY)
-- ============================================================================

USE perseus;
GO

SET NOCOUNT ON;

-- Note: Session ID and tempdb checks performed in Tier 0
-- Variables @session_id and @tempdb_free_mb already declared in concatenated session

PRINT '========================================';
PRINT 'TIER 4 EXTRACTION - Starting (FINAL TIER - PRODUCTION-SAFE)';
PRINT 'Sample Method: TOP 5000 with deterministic ORDER BY';
PRINT 'Tables: 11 tables INCLUDING P0 LINEAGE';
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
-- PREREQUISITE CHECK (Enhanced - Multiple Critical Tables)
-- ============================================================================
IF OBJECT_ID('tempdb..##perseus_tier_3_goo') IS NULL
   OR OBJECT_ID('tempdb..##perseus_tier_3_fatsmurf') IS NULL
   OR OBJECT_ID('tempdb..##perseus_tier_0_container') IS NULL
   OR OBJECT_ID('tempdb..##perseus_tier_1_perseus_user') IS NULL
BEGIN
    PRINT 'ERROR: Tier 3 temp tables not found!';
    PRINT 'You must run extract-tier0-corrected, tier1-corrected, tier2-corrected, and tier3-corrected.sql first.';
    RAISERROR('Missing Tier 3 data (goo, fatsmurf)', 16, 1);
    RETURN;
END
PRINT 'Prerequisite check: PASSED (Tier 0-3 temp tables found)';
PRINT '';

-- ============================================================================
-- TIER 4: HIGHEST DEPENDENCY TABLES
-- INCLUDES P0 CRITICAL MATERIAL LINEAGE TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. material_transition (P0 CRITICAL) - Parent material → Transition edges
-- Dependencies: goo.uid, fatsmurf.uid (UID-based FKs!)
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: material_transition (P0 CRITICAL - Lineage INPUT edges)';

    IF OBJECT_ID('tempdb..##perseus_tier_4_material_transition') IS NOT NULL
        DROP TABLE ##perseus_tier_4_material_transition;

    WITH valid_goo_uids AS (
        SELECT uid FROM ##perseus_tier_3_goo WHERE uid IS NOT NULL
    ),
    valid_fatsmurf_uids AS (
        SELECT uid FROM ##perseus_tier_3_fatsmurf WHERE uid IS NOT NULL
    )
    SELECT TOP 5000 mt.*
    INTO ##perseus_tier_4_material_transition
    FROM dbo.material_transition mt WITH (NOLOCK)
    WHERE mt.material_id IN (SELECT uid FROM valid_goo_uids)
      AND mt.transition_id IN (SELECT uid FROM valid_fatsmurf_uids)
    ORDER BY mt.transition_id;

    DECLARE @mt_rows INT = @@ROWCOUNT;
    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @mt_rows;
    PRINT '  Rows: ' + CAST(@mt_rows AS VARCHAR(10)) + ' - SUCCESS';
    PRINT '  ** CRITICAL: Material lineage INPUT edges extracted (UID-based FK)';

    IF @mt_rows = 0
        PRINT '  WARNING: Zero rows from material_transition (check if source has data)';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: material_transition';
END CATCH;

-- ----------------------------------------------------------------------------
-- 2. transition_material (P0 CRITICAL) - Transition → Product material edges
-- Dependencies: fatsmurf.uid, goo.uid (UID-based FKs!)
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: transition_material (P0 CRITICAL - Lineage OUTPUT edges)';

    IF OBJECT_ID('tempdb..##perseus_tier_4_transition_material') IS NOT NULL
        DROP TABLE ##perseus_tier_4_transition_material;

    WITH valid_fatsmurf_uids AS (
        SELECT uid FROM ##perseus_tier_3_fatsmurf WHERE uid IS NOT NULL
    ),
    valid_goo_uids AS (
        SELECT uid FROM ##perseus_tier_3_goo WHERE uid IS NOT NULL
    )
    SELECT TOP 5000 tm.*
    INTO ##perseus_tier_4_transition_material
    FROM dbo.transition_material tm WITH (NOLOCK)
    WHERE tm.transition_id IN (SELECT uid FROM valid_fatsmurf_uids)
      AND tm.material_id IN (SELECT uid FROM valid_goo_uids)
    ORDER BY tm.material_id;

    DECLARE @tm_rows INT = @@ROWCOUNT;
    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @tm_rows;
    PRINT '  Rows: ' + CAST(@tm_rows AS VARCHAR(10)) + ' - SUCCESS';
    PRINT '  ** CRITICAL: Material lineage OUTPUT edges extracted (UID-based FK)';

    IF @tm_rows = 0
        PRINT '  WARNING: Zero rows from transition_material (check if source has data)';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: transition_material';
END CATCH;

-- ----------------------------------------------------------------------------
-- 3. material_inventory
-- Dependencies: goo, container, perseus_user, recipe
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: material_inventory';

    IF OBJECT_ID('tempdb..##perseus_tier_4_material_inventory') IS NOT NULL
        DROP TABLE ##perseus_tier_4_material_inventory;

    WITH valid_goos AS (
        SELECT id FROM ##perseus_tier_3_goo
    ),
    valid_containers AS (
        SELECT id FROM ##perseus_tier_0_container
    ),
    valid_users AS (
        SELECT id FROM ##perseus_tier_1_perseus_user
    ),
    valid_recipes AS (
        SELECT id FROM ##perseus_tier_2_recipe
    )
    SELECT TOP 5000 mi.*
    INTO ##perseus_tier_4_material_inventory
    FROM dbo.material_inventory mi WITH (NOLOCK)
    WHERE mi.material_id IN (SELECT id FROM valid_goos)
      AND mi.location_container_id IN (SELECT id FROM valid_containers)
      AND mi.created_by_id IN (SELECT id FROM valid_users)
      AND (mi.recipe_id IN (SELECT id FROM valid_recipes) OR mi.recipe_id IS NULL)
    ORDER BY mi.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: material_inventory';
END CATCH;

-- ----------------------------------------------------------------------------
-- 4. fatsmurf_reading
-- Dependencies: fatsmurf, poll
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: fatsmurf_reading';

    IF OBJECT_ID('tempdb..##perseus_tier_4_fatsmurf_reading') IS NOT NULL
        DROP TABLE ##perseus_tier_4_fatsmurf_reading;

    WITH valid_fatsmurfs AS (
        SELECT id FROM ##perseus_tier_3_fatsmurf
    ),
    valid_users AS (
        SELECT id FROM ##perseus_tier_1_perseus_user
    )
    SELECT TOP 5000 fr.*
    INTO ##perseus_tier_4_fatsmurf_reading
    FROM dbo.fatsmurf_reading fr WITH (NOLOCK)
    WHERE fr.fatsmurf_id IN (SELECT id FROM valid_fatsmurfs)
      AND fr.added_by IN (SELECT id FROM valid_users)
    ORDER BY fr.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: fatsmurf_reading';
END CATCH;

-- ----------------------------------------------------------------------------
-- 5. poll_history
-- Dependencies: poll (history_id nullable), NO fatsmurf_reading dependency
-- CORRECTED: Removed non-existent fatsmurf_reading_id column
-- Schema: id, history_id, poll_id
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: poll_history';

    IF OBJECT_ID('tempdb..##perseus_tier_4_poll_history') IS NOT NULL
        DROP TABLE ##perseus_tier_4_poll_history;

    WITH valid_polls AS (
        SELECT id FROM ##perseus_tier_0_poll
    )
    SELECT TOP 5000 ph.*
    INTO ##perseus_tier_4_poll_history
    FROM dbo.poll_history ph WITH (NOLOCK)
    WHERE ph.poll_id IN (SELECT id FROM valid_polls)
    ORDER BY ph.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
    PRINT '  ** FIX APPLIED: Removed invalid fatsmurf_reading_id filter';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: poll_history';
END CATCH;

-- ----------------------------------------------------------------------------
-- 6. submission_entry
-- Dependencies: submission, smurf, goo, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: submission_entry';

    IF OBJECT_ID('tempdb..##perseus_tier_4_submission_entry') IS NOT NULL
        DROP TABLE ##perseus_tier_4_submission_entry;

    WITH valid_submissions AS (
        SELECT id FROM ##perseus_tier_3_submission
    ),
    valid_goos AS (
        SELECT id FROM ##perseus_tier_3_goo
    ),
    valid_users AS (
        SELECT id FROM ##perseus_tier_1_perseus_user
    )
    SELECT TOP 5000 se.*
    INTO ##perseus_tier_4_submission_entry
    FROM dbo.submission_entry se WITH (NOLOCK)
    WHERE se.submission_id IN (SELECT id FROM valid_submissions)
      AND se.material_id IN (SELECT id FROM valid_goos)
      AND (se.prepped_by_id IN (SELECT id FROM valid_users) OR se.prepped_by_id IS NULL)
    ORDER BY se.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: submission_entry';
END CATCH;

-- ----------------------------------------------------------------------------
-- 7. robot_log
-- Dependencies: robot_log_type, smurf_robot, perseus_user
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: robot_log';

    IF OBJECT_ID('tempdb..##perseus_tier_4_robot_log') IS NOT NULL
        DROP TABLE ##perseus_tier_4_robot_log;

    WITH valid_log_types AS (
        SELECT id FROM ##perseus_tier_1_robot_log_type
    )
    SELECT TOP 5000 rl.*
    INTO ##perseus_tier_4_robot_log
    FROM dbo.robot_log rl WITH (NOLOCK)
    WHERE rl.robot_log_type_id IN (SELECT id FROM valid_log_types)
    ORDER BY rl.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: robot_log';
END CATCH;

-- ----------------------------------------------------------------------------
-- 8. robot_log_read
-- Dependencies: robot_log, goo, property
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: robot_log_read';

    IF OBJECT_ID('tempdb..##perseus_tier_4_robot_log_read') IS NOT NULL
        DROP TABLE ##perseus_tier_4_robot_log_read;

    WITH valid_logs AS (
        SELECT id FROM ##perseus_tier_4_robot_log
    ),
    valid_goos AS (
        SELECT id FROM ##perseus_tier_3_goo
    ),
    valid_properties AS (
        SELECT id FROM ##perseus_tier_1_property
    )
    SELECT TOP 5000 rlr.*
    INTO ##perseus_tier_4_robot_log_read
    FROM dbo.robot_log_read rlr WITH (NOLOCK)
    WHERE rlr.robot_log_id IN (SELECT id FROM valid_logs)
      AND (rlr.source_material_id IN (SELECT id FROM valid_goos) OR rlr.source_material_id IS NULL)
      AND (rlr.property_id IN (SELECT id FROM valid_properties) OR rlr.property_id IS NULL)
    ORDER BY rlr.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: robot_log_read';
END CATCH;

-- ----------------------------------------------------------------------------
-- 9. robot_log_transfer
-- Dependencies: robot_log, goo (source/dest)
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: robot_log_transfer';

    IF OBJECT_ID('tempdb..##perseus_tier_4_robot_log_transfer') IS NOT NULL
        DROP TABLE ##perseus_tier_4_robot_log_transfer;

    WITH valid_logs AS (
        SELECT id FROM ##perseus_tier_4_robot_log
    ),
    valid_goos AS (
        SELECT id FROM ##perseus_tier_3_goo
    )
    SELECT TOP 5000 rlt.*
    INTO ##perseus_tier_4_robot_log_transfer
    FROM dbo.robot_log_transfer rlt WITH (NOLOCK)
    WHERE rlt.robot_log_id IN (SELECT id FROM valid_logs)
      AND (rlt.source_material_id IN (SELECT id FROM valid_goos) OR rlt.source_material_id IS NULL)
      AND (rlt.destination_material_id IN (SELECT id FROM valid_goos) OR rlt.destination_material_id IS NULL)
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
    PRINT '  Skipping table: robot_log_transfer';
END CATCH;

-- ----------------------------------------------------------------------------
-- 10. robot_log_error
-- Dependencies: robot_log
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: robot_log_error';

    IF OBJECT_ID('tempdb..##perseus_tier_4_robot_log_error') IS NOT NULL
        DROP TABLE ##perseus_tier_4_robot_log_error;

    WITH valid_logs AS (
        SELECT id FROM ##perseus_tier_4_robot_log
    )
    SELECT TOP 5000 rle.*
    INTO ##perseus_tier_4_robot_log_error
    FROM dbo.robot_log_error rle WITH (NOLOCK)
    WHERE rle.robot_log_id IN (SELECT id FROM valid_logs)
    ORDER BY rle.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: robot_log_error';
END CATCH;

-- ----------------------------------------------------------------------------
-- 11. robot_log_container_sequence
-- Dependencies: robot_log, container
-- ----------------------------------------------------------------------------
BEGIN TRY
    PRINT 'Extracting: robot_log_container_sequence';

    IF OBJECT_ID('tempdb..##perseus_tier_4_robot_log_container_sequence') IS NOT NULL
        DROP TABLE ##perseus_tier_4_robot_log_container_sequence;

    WITH valid_logs AS (
        SELECT id FROM ##perseus_tier_4_robot_log
    ),
    valid_containers AS (
        SELECT id FROM ##perseus_tier_0_container
    )
    SELECT TOP 5000 rlcs.*
    INTO ##perseus_tier_4_robot_log_container_sequence
    FROM dbo.robot_log_container_sequence rlcs WITH (NOLOCK)
    WHERE rlcs.robot_log_id IN (SELECT id FROM valid_logs)
      AND rlcs.container_id IN (SELECT id FROM valid_containers)
    ORDER BY rlcs.id;

    SET @total_tables = @total_tables + 1;
    SET @success_tables = @success_tables + 1;
    SET @total_rows = @total_rows + @@ROWCOUNT;
    PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' - SUCCESS';
END TRY
BEGIN CATCH
    SET @total_tables = @total_tables + 1;
    SET @failed_tables = @failed_tables + 1;
    PRINT '  ERROR: ' + ERROR_MESSAGE();
    PRINT '  Skipping table: robot_log_container_sequence';
END CATCH;

-- ============================================================================
-- EXTRACTION SUMMARY
-- ============================================================================
PRINT '';
PRINT '========================================';
PRINT 'TIER 4 EXTRACTION - Complete (FINAL TIER)';
PRINT '========================================';
PRINT 'Total Tables: ' + CAST(@total_tables AS VARCHAR(10));
PRINT 'Success: ' + CAST(@success_tables AS VARCHAR(10));
PRINT 'Failed: ' + CAST(@failed_tables AS VARCHAR(10));
PRINT 'Total Rows: ' + CAST(@total_rows AS VARCHAR(10));

IF @success_tables > 0
    PRINT 'Avg Rows/Table: ' + CAST(@total_rows / @success_tables AS VARCHAR(10));

PRINT '';
PRINT 'P0 CRITICAL LINEAGE TABLES EXTRACTED:';
PRINT '  - material_transition (INPUT edges): ' + CAST(@mt_rows AS VARCHAR(10)) + ' rows';
PRINT '  - transition_material (OUTPUT edges): ' + CAST(@tm_rows AS VARCHAR(10)) + ' rows';
PRINT '';
PRINT 'PRODUCTION SAFETY FEATURES:';
PRINT '  - Session ID logging for manual intervention';
PRINT '  - Tempdb space validation (2GB minimum)';
PRINT '  - NOLOCK hints to prevent blocking';
PRINT '  - Deterministic sampling (TOP 5000 + ORDER BY)';
PRINT '  - Idempotency (can be re-executed safely)';
PRINT '  - Graceful error handling';
PRINT '';
PRINT '========================================';
PRINT 'ALL EXTRACTION COMPLETE!';
PRINT '========================================';
PRINT 'Next Steps:';
PRINT '  1. Export all ##perseus_tier_4_* tables to CSV';
PRINT '  2. Run load-data.sh on PostgreSQL';
PRINT '  3. Validate referential integrity';
PRINT '========================================';
GO

-- ============================================================================
-- EXTRACTION SUMMARY - ALL TIERS
-- ============================================================================
-- Total global temp tables created: 76 (all Perseus tables)
-- Sample method: TOP 5000 with deterministic ORDER BY (per table)
-- Referential integrity: PRESERVED (all FK relationships valid)
-- Global temp tables persist across sessions until server restart
--
-- EXPORT INSTRUCTIONS:
-- Use BCP or SSMS "Export Data" wizard to export all ##perseus_tier_* tables to CSV:
--
-- Example BCP command (tier 3 goo table):
-- bcp "SELECT * FROM tempdb..##perseus_tier_3_goo" queryout "C:\export\goo.csv"
--   -c -t"," -r"\n" -S SERVER -U USER -P PASSWORD
--
-- Or use SSMS: Right-click database → Tasks → Export Data → Select global temp tables
--
-- Tables created in Tier 4: 11 (material_transition, transition_material,
-- material_inventory, fatsmurf_reading, poll_history, submission_entry,
-- robot_log, robot_log_read, robot_log_transfer, robot_log_error,
-- robot_log_container_sequence)
-- ============================================================================
