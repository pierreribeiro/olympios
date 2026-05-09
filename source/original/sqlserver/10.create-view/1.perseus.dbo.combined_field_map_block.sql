USE [perseus]
GO
            
CREATE VIEW combined_field_map_block AS
SELECT id, filter, scope FROM field_map_block
UNION
-- All FatSmurf Readings
SELECT 
id + 1000,
'isSmurf('+CONVERT(VARCHAR(10), id)+')', 'FatSmurfReading' 
FROM smurf
UNION
-- Fields for fatsmurf list and csv
SELECT 
id + 2000,
'isSmurf('+CONVERT(VARCHAR(10), id)+')', 'FatSmurf' 
FROM smurf
UNION
-- for single reading fatsmurf editing
SELECT 
id + 3000,
'isSmurfWithOneReading('+CONVERT(VARCHAR(10), id)+')', 'FatSmurf' 
FROM smurf

