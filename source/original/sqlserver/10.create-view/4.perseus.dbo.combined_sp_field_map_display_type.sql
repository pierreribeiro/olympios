USE [perseus]
GO
            
CREATE VIEW combined_sp_field_map_display_type WITH SCHEMABINDING AS

-- fatsmurf reading editing
SELECT 
sp.id + 10000 + dl.id AS id,
sp.id + 20000 AS field_map_id, 
dl.id AS display_type_id, 
'getPollValueBySmurfPropertyId('+CONVERT(VARCHAR(25), sp.id)+')' AS display, 
5 AS display_layout_id,
0 AS manditory
FROM dbo.smurf_property sp
JOIN dbo.smurf s ON s.id = sp.smurf_id
JOIN dbo.property p ON p.id = sp.property_id
CROSS JOIN dbo.display_layout dl
WHERE sp.disabled = 0
AND dl.id IN (1)
UNION
-- fatsmurf reading table
SELECT 
sp.id + 20000 + dl.id AS id,
sp.id + 20000 AS field_map_id, 
dl.id AS display_type_id, 
'getPollValueBySmurfPropertyId('+CONVERT(VARCHAR(25), sp.id)+')'  AS display, 
7 AS display_layout_id,
0 AS manditory
FROM dbo.smurf_property sp
JOIN dbo.smurf s ON s.id = sp.smurf_id
JOIN dbo.property p ON p.id = sp.property_id
CROSS JOIN dbo.display_layout dl
WHERE sp.disabled = 0
AND dl.id IN (7)
UNION
-- fatsmurf listing
SELECT 
sp.id + 30000 + dl.id AS id,
sp.id + 30000 AS field_map_id, 
dl.id AS display_type_id, 
'getPollValueStringBySmurfPropertyId('+CONVERT(VARCHAR(25), sp.id)+')' AS display, 
7 AS display_layout_id,
0 AS manditory
FROM dbo.smurf_property sp
JOIN dbo.smurf s ON s.id = sp.smurf_id
JOIN dbo.property p ON p.id = sp.property_id
CROSS JOIN dbo.display_layout dl
WHERE sp.disabled = 0
AND dl.id IN (3)
UNION
-- fatsmurf csv
SELECT 
sp.id + 40000 + dl.id AS id,
sp.id + 30000 AS field_map_id, 
dl.id AS display_type_id, 
'getPollValueStringBySmurfPropertyId('+CONVERT(VARCHAR(25), sp.id)+')' AS display, 
7 AS display_layout_id,
0 AS manditory
FROM dbo.smurf_property sp
JOIN dbo.smurf s ON s.id = sp.smurf_id
JOIN dbo.property p ON p.id = sp.property_id
CROSS JOIN dbo.display_layout dl
WHERE sp.disabled = 0
AND dl.id IN (6)
UNION
-- fatsmurf single reading editing
SELECT 
sp.id + 50000 + dl.id AS id,
sp.id + 40000 AS field_map_id, 
dl.id AS display_type_id, 
'getPollValueBySmurfPropertyId('+CONVERT(VARCHAR(25), sp.id)+')' AS display, 
5 AS display_layout_id,
0 AS manditory
FROM dbo.smurf_property sp
JOIN dbo.smurf s ON s.id = sp.smurf_id
JOIN dbo.property p ON p.id = sp.property_id
CROSS JOIN dbo.display_layout dl
WHERE sp.disabled = 0
AND dl.id IN (1)

