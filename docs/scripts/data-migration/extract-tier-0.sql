-- ============================================================================
-- SQL Server Data Extraction Script - Tier 0 (Base Tables) - PRODUCTION-SAFE
-- Perseus Database Migration: TOP 5000 Development/Testing Extract
-- ============================================================================
-- Purpose: Extract TOP 5000 deterministic sample from 22 Tier 0 tables (no FK dependencies)
-- Execution: Run on SQL Server (source database)
-- Output: Global temp tables (##perseus_tier_0_*) for downstream tier extraction + CSV exports
-- Version: 7.0 (DEVELOPMENT/TESTING - Consistent TOP 5000 sampling)
-- ============================================================================
-- CHANGES v7.0 (Development/Testing Optimization):
--   - STANDARDIZED SAMPLING: All tables use TOP 5000 for consistent dev/test datasets
--   - DETERMINISTIC ORDERING: All tables have ORDER BY <pk_column> for repeatability
--   - REMOVED: Variable sampling (TOP PERCENT, TABLESAMPLE) for predictability
--   - PRESERVED: Primary key indexes on temp tables for tier-1+ performance
--   - ESTIMATED: 1-2 min execution, ~50-100MB total size
-- ============================================================================
-- PREVIOUS CHANGES v6.0:
--   - Hybrid sampling strategy (TOP PERCENT for small, TABLESAMPLE for large)
--   - Added primary key indexes for join performance
-- ============================================================================

USE perseus;
GO

SET NOCOUNT ON;

-- Log session ID for potential manual kill
DECLARE @session_id INT = @@SPID;
PRINT '========================================';
PRINT 'SESSION ID: ' + CAST(@session_id AS VARCHAR(10));
PRINT 'IMPORTANT: Save this ID for manual intervention if needed';
PRINT '========================================';
PRINT '';

-- Check tempdb free space (require minimum 2GB)
DECLARE @tempdb_free_mb INT;
SELECT @tempdb_free_mb = SUM(unallocated_extent_page_count) * 8 / 1024
FROM tempdb.sys.dm_db_file_space_usage;

PRINT 'Tempdb Free Space: ' + CAST(@tempdb_free_mb AS VARCHAR(10)) + ' MB';

IF @tempdb_free_mb < 2000
BEGIN
    RAISERROR('INSUFFICIENT TEMPDB SPACE. Free: %d MB. Required: 2000 MB. Aborting.', 16, 1, @tempdb_free_mb);
    RETURN;
END;
PRINT 'Tempdb space check: PASSED';
PRINT '';

PRINT '========================================';
PRINT 'TIER 0 EXTRACTION - Starting (DEVELOPMENT/TESTING)';
PRINT 'Strategy: TOP 5000 with deterministic ORDER BY for all tables';
PRINT 'Tables: 22 base tables (no dependencies)';
PRINT '========================================';
PRINT '';

-- ============================================================================
-- TIER 0: BASE TABLES - ALL TABLES USE TOP 5000 + ORDER BY
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Permissions - NO ID COLUMN (Very small: ~1 row)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: Permissions';
IF OBJECT_ID('tempdb..##perseus_tier_0_Permissions') IS NOT NULL
    DROP TABLE ##perseus_tier_0_Permissions;
SELECT TOP 5000 *
INTO ##perseus_tier_0_Permissions
FROM dbo.Permissions WITH (NOLOCK)
ORDER BY (SELECT NULL);
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 2. unit (Small: ~5 rows)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: unit';
IF OBJECT_ID('tempdb..##perseus_tier_0_unit') IS NOT NULL
    DROP TABLE ##perseus_tier_0_unit;
SELECT TOP 5000 *
INTO ##perseus_tier_0_unit
FROM dbo.unit WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- Create index for tier-1 joins
CREATE CLUSTERED INDEX IX_unit_id ON ##perseus_tier_0_unit(id);

-- ----------------------------------------------------------------------------
-- 3. cm_unit_dimensions (Small: ~2 rows)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: cm_unit_dimensions';
IF OBJECT_ID('tempdb..##perseus_tier_0_cm_unit_dimensions') IS NOT NULL
    DROP TABLE ##perseus_tier_0_cm_unit_dimensions;
SELECT TOP 5000 *
INTO ##perseus_tier_0_cm_unit_dimensions
FROM dbo.cm_unit_dimensions WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 4. cm_user (Small: ~200 rows)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: cm_user';
IF OBJECT_ID('tempdb..##perseus_tier_0_cm_user') IS NOT NULL
    DROP TABLE ##perseus_tier_0_cm_user;
SELECT TOP 5000 *
INTO ##perseus_tier_0_cm_user
FROM dbo.cm_user WITH (NOLOCK)
ORDER BY user_id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 5. cm_user_group - NO PK (Small: ~667 rows)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: cm_user_group';
IF OBJECT_ID('tempdb..##perseus_tier_0_cm_user_group') IS NOT NULL
    DROP TABLE ##perseus_tier_0_cm_user_group;
SELECT TOP 5000 *
INTO ##perseus_tier_0_cm_user_group
FROM dbo.cm_user_group WITH (NOLOCK)
ORDER BY (SELECT NULL);
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 6. coa (Very small: ~1 row)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: coa';
IF OBJECT_ID('tempdb..##perseus_tier_0_coa') IS NOT NULL
    DROP TABLE ##perseus_tier_0_coa;
SELECT TOP 5000 *
INTO ##perseus_tier_0_coa
FROM dbo.coa WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 7. coa_spec (Very small: ~1 row)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: coa_spec';
IF OBJECT_ID('tempdb..##perseus_tier_0_coa_spec') IS NOT NULL
    DROP TABLE ##perseus_tier_0_coa_spec;
SELECT TOP 5000 *
INTO ##perseus_tier_0_coa_spec
FROM dbo.coa_spec WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 8. color - NO ID COLUMN (Small: ~17 rows)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: color';
IF OBJECT_ID('tempdb..##perseus_tier_0_color') IS NOT NULL
    DROP TABLE ##perseus_tier_0_color;
SELECT TOP 5000 *
INTO ##perseus_tier_0_color
FROM dbo.color WITH (NOLOCK)
ORDER BY (SELECT NULL);
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 9. manufacturer (Small: estimated <1000 rows)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: manufacturer';
IF OBJECT_ID('tempdb..##perseus_tier_0_manufacturer') IS NOT NULL
    DROP TABLE ##perseus_tier_0_manufacturer;
SELECT TOP 5000 *
INTO ##perseus_tier_0_manufacturer
FROM dbo.manufacturer WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

CREATE CLUSTERED INDEX IX_manufacturer_id ON ##perseus_tier_0_manufacturer(id);

-- ----------------------------------------------------------------------------
-- 10. display_layout (Small: estimated <100 rows)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: display_layout';
IF OBJECT_ID('tempdb..##perseus_tier_0_display_layout') IS NOT NULL
    DROP TABLE ##perseus_tier_0_display_layout;
SELECT TOP 5000 *
INTO ##perseus_tier_0_display_layout
FROM dbo.display_layout WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 11. display_type (Small: estimated <100 rows)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: display_type';
IF OBJECT_ID('tempdb..##perseus_tier_0_display_type') IS NOT NULL
    DROP TABLE ##perseus_tier_0_display_type;
SELECT TOP 5000 *
INTO ##perseus_tier_0_display_type
FROM dbo.display_type WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 12. external_goo_type (Small/Medium: estimated <5000 rows)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: external_goo_type';
IF OBJECT_ID('tempdb..##perseus_tier_0_external_goo_type') IS NOT NULL
    DROP TABLE ##perseus_tier_0_external_goo_type;
SELECT TOP 5000 *
INTO ##perseus_tier_0_external_goo_type
FROM dbo.external_goo_type WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 13. field_map (Small/Medium: estimated <5000 rows)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: field_map';
IF OBJECT_ID('tempdb..##perseus_tier_0_field_map') IS NOT NULL
    DROP TABLE ##perseus_tier_0_field_map;
SELECT TOP 5000 *
INTO ##perseus_tier_0_field_map
FROM dbo.field_map WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 14. PerseusTableAndRowCounts - NO ID (Medium: ~25k rows)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: PerseusTableAndRowCounts';
IF OBJECT_ID('tempdb..##perseus_tier_0_PerseusTableAndRowCounts') IS NOT NULL
    DROP TABLE ##perseus_tier_0_PerseusTableAndRowCounts;
SELECT TOP 5000 *
INTO ##perseus_tier_0_PerseusTableAndRowCounts
FROM dbo.PerseusTableAndRowCounts WITH (NOLOCK)
ORDER BY (SELECT NULL);
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 15. Scraper - BLOB column excluded (179k rows, 78GB source)
-- ----------------------------------------------------------------------------
-- Scraper table contains file scraping logs with large BLOB attachments
-- Average row size: 445KB (78GB / 179k rows) due to File varbinary(max) column
-- Solution: Extract schema with File=NULL to preserve table structure
-- This avoids 78GB BLOB export while maintaining PostgreSQL schema compatibility
PRINT 'Extracting: Scraper (File column set to NULL - BLOB excluded)';
IF OBJECT_ID('tempdb..##perseus_tier_0_Scraper') IS NOT NULL
    DROP TABLE ##perseus_tier_0_Scraper;

SELECT TOP 5000
    ID, Timestamp, Message, FileType, Filename, FilenameSavedAs,
    ReceivedFrom, Result, Complete, ScraperID, ScrapingStartedOn,
    ScrapingFinishedOn, ScrapingStatus, ScraperSendTo, ScraperMessage,
    Active, ControlFileID, DocumentID,
    CAST(NULL AS varbinary(max)) AS [File]  -- Preserve column, NULL data
INTO ##perseus_tier_0_Scraper
FROM dbo.Scraper WITH (NOLOCK)
ORDER BY ID;

PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
PRINT '  ** File column preserved as NULL (BLOB data excluded)';
PRINT '  ** Reduced from 78GB to ~10MB by excluding BLOB data';

-- ----------------------------------------------------------------------------
-- 16. poll (LARGE: ~718k rows) - CRITICAL PERFORMANCE
-- ----------------------------------------------------------------------------
PRINT 'Extracting: poll';
IF OBJECT_ID('tempdb..##perseus_tier_0_poll') IS NOT NULL
    DROP TABLE ##perseus_tier_0_poll;
SELECT TOP 5000 *
INTO ##perseus_tier_0_poll
FROM dbo.poll WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

CREATE CLUSTERED INDEX IX_poll_id ON ##perseus_tier_0_poll(id);

-- ----------------------------------------------------------------------------
-- 17. container (LARGE: ~182k rows) - P1 CRITICAL
-- ----------------------------------------------------------------------------
PRINT 'Extracting: container';
IF OBJECT_ID('tempdb..##perseus_tier_0_container') IS NOT NULL
    DROP TABLE ##perseus_tier_0_container;
SELECT TOP 5000 *
INTO ##perseus_tier_0_container
FROM dbo.container WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

CREATE CLUSTERED INDEX IX_container_id ON ##perseus_tier_0_container(id);

-- ----------------------------------------------------------------------------
-- 18. container_type (Medium: estimated ~1000 rows)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: container_type';
IF OBJECT_ID('tempdb..##perseus_tier_0_container_type') IS NOT NULL
    DROP TABLE ##perseus_tier_0_container_type;
SELECT TOP 5000 *
INTO ##perseus_tier_0_container_type
FROM dbo.container_type WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

CREATE CLUSTERED INDEX IX_container_type_id ON ##perseus_tier_0_container_type(id);

-- ----------------------------------------------------------------------------
-- 19. goo_type (Medium: estimated ~5000 rows) - P0 CRITICAL
-- ----------------------------------------------------------------------------
PRINT 'Extracting: goo_type (P0 CRITICAL)';
IF OBJECT_ID('tempdb..##perseus_tier_0_goo_type') IS NOT NULL
    DROP TABLE ##perseus_tier_0_goo_type;
SELECT TOP 5000 *
INTO ##perseus_tier_0_goo_type
FROM dbo.goo_type WITH (NOLOCK)
ORDER BY id;
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

CREATE CLUSTERED INDEX IX_goo_type_id ON ##perseus_tier_0_goo_type(id);

-- ----------------------------------------------------------------------------
-- 20. m_downstream - NO ID (Large cache table) - P0 CRITICAL
-- ----------------------------------------------------------------------------
PRINT 'Extracting: m_downstream (P0 CRITICAL)';
IF OBJECT_ID('tempdb..##perseus_tier_0_m_downstream') IS NOT NULL
    DROP TABLE ##perseus_tier_0_m_downstream;
SELECT TOP 5000 *
INTO ##perseus_tier_0_m_downstream
FROM dbo.m_downstream WITH (NOLOCK)
ORDER BY (SELECT NULL);
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 21. m_upstream - NO ID (MEGA TABLE: 686M rows, 153GB) - P0 CRITICAL
-- ----------------------------------------------------------------------------
PRINT 'Extracting: m_upstream (P0 CRITICAL)';
IF OBJECT_ID('tempdb..##perseus_tier_0_m_upstream') IS NOT NULL
    DROP TABLE ##perseus_tier_0_m_upstream;
SELECT TOP 5000 *
INTO ##perseus_tier_0_m_upstream
FROM dbo.m_upstream WITH (NOLOCK)
ORDER BY (SELECT NULL);
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

-- ----------------------------------------------------------------------------
-- 22. m_upstream_dirty_leaves - NO ID (Medium/Large)
-- ----------------------------------------------------------------------------
PRINT 'Extracting: m_upstream_dirty_leaves';
IF OBJECT_ID('tempdb..##perseus_tier_0_m_upstream_dirty_leaves') IS NOT NULL
    DROP TABLE ##perseus_tier_0_m_upstream_dirty_leaves;
SELECT TOP 5000 *
INTO ##perseus_tier_0_m_upstream_dirty_leaves
FROM dbo.m_upstream_dirty_leaves WITH (NOLOCK)
ORDER BY (SELECT NULL);
PRINT '  Rows: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

PRINT '';
PRINT '========================================';
PRINT 'TIER 0 EXTRACTION - Complete';
PRINT 'Extracted: 22 tables';
PRINT 'Strategy: TOP 5000 with deterministic ORDER BY';
PRINT 'Next: Run extract-tier-1.sql';
PRINT '========================================';
GO

-- ============================================================================
-- PERFORMANCE NOTES v7.0
-- ============================================================================
-- 1. ALL tables: SELECT TOP 5000 with ORDER BY <pk_column>
--    - Deterministic, consistent sample size across all tables
--    - ORDER BY (SELECT NULL) for tables without primary keys
--    - Ideal for development/testing environments
-- 2. Tables without PK: Permissions, cm_user_group, color,
--    PerseusTableAndRowCounts, m_downstream, m_upstream, m_upstream_dirty_leaves
-- 3. Indexes preserved on critical FK columns for tier-1+ join performance
-- 4. Estimated execution time: 1-2 minutes
-- 5. Estimated total size: ~50-100MB (down from 15% sample)
-- ============================================================================
