#!/bin/bash
# Apply production-safe modifications to tier3 and tier4 extraction scripts

for tier in tier3 tier4; do
    echo "Processing extract-${tier}.sql..."
    
    # Read the corrected file
    input_file="extract-${tier}-corrected.sql"
    output_file="extract-${tier}.sql"
    
    # Create header with session ID and tempdb check
    cat > "$output_file" << 'EOFHEADER'
-- ============================================================================
-- SQL Server Data Extraction Script - TIERX - PRODUCTION-SAFE
-- Perseus Database Migration: 15% Sample Extraction with FK Filtering
-- ============================================================================
EOFHEADER

    # Replace TIERX placeholder
    sed -i '' "s/TIERX/$(echo $tier | tr 'tier' 'Tier')/g" "$output_file"
    
    # Add rest of header from corrected file (skip first 10 lines, take next 10)
    sed -n '5,9p' "$input_file" | sed 's/CORRECTED/PRODUCTION-SAFE/' | sed 's/2\.0.*/3.0 (Production-Safe: tempdb checks, NOLOCK, deterministic sampling)/' >> "$output_file"
    
    # Add production safety preamble
    cat >> "$output_file" << 'EOFPREAMBLE'

USE perseus;
GO

SET NOCOUNT ON;

-- Log session ID
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

EOFPREAMBLE

    # Process the body: skip header, add NOLOCK and modulo filtering
    sed -n '14,$p' "$input_file" | \
        sed 's/ORDER BY NEWID();/;/' | \
        sed 's/FROM dbo\.\([a-z_]*\) \([a-z]*\)$/FROM dbo.\1 \2 WITH (NOLOCK)/' | \
        sed 's/FROM dbo\.\([a-z_]*\)$/FROM dbo.\1 WITH (NOLOCK)/' | \
        sed '/^    SELECT TOP 15 PERCENT/,/ORDER BY/{ 
            /ORDER BY/d
            /WHERE/,/;/{ 
                /;$/i\      AND (CAST(COALESCE(id, goo_id, container_id, 1) AS BIGINT) % 7 = 0\
           OR CAST(COALESCE(id, goo_id, container_id, 1) AS BIGINT) % 7 = 1);
                s/ORDER BY NEWID();//
            }
        }' | \
        sed 's/TIER [0-9] EXTRACTION - Starting/& (PRODUCTION-SAFE)/' | \
        sed 's/Sample Rate: 15%/Sample Rate: ~15% (deterministic modulo-based)/' | \
        sed 's/CORRECTED/PRODUCTION-SAFE/g' >> "$output_file"
    
    echo "Created $output_file"
done

echo "Done! Tier 3 and 4 production-safe scripts created."
