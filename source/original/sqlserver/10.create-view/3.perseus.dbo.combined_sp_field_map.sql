USE [perseus]
GO
            
CREATE VIEW combined_sp_field_map WITH SCHEMABINDING AS 
-- all fatsmurf reading
SELECT
sp.id + 20000 AS id,
sp.smurf_id + 1000 AS field_map_block_id,
p.name + CASE WHEN u.name IS NOT NULL THEN ' ('+u.name+')' ELSE '' END AS name, 
CONVERT(VARCHAR(50), NULL)  AS description,
sp.sort_order AS display_order, 
'setPollValueBySpid('+CONVERT(VARCHAR(25), sp.id)+', ?)' AS setter,
CASE WHEN po.property_id IS NULL THEN NULL ELSE 'PropertyPeer::getLookupByPropertyId('+CAST(po.property_id AS VARCHAR(10))+')' END AS [lookup],
CONVERT(VARCHAR(50), NULL)  AS lookup_service,
1 AS nullable,
CASE WHEN po.property_id IS NOT NULL THEN 12 ELSE 10 END field_map_type_id,
CONVERT(VARCHAR(50), NULL)  AS database_id,
1  AS save_sequence,
CONVERT(VARCHAR(50), NULL)  AS onchange,
CASE WHEN s.class_id = 2 THEN 9 ELSE 12 END AS field_map_set_id
FROM dbo.smurf_property sp
JOIN dbo.smurf s ON sp.smurf_id = s.id
JOIN dbo.property p ON sp.property_id = p.id
LEFT JOIN dbo.unit u ON u.id = p.unit_id
LEFT JOIN dbo.property_option po ON po.property_id = p.id
UNION
-- fatsmurfs for list and csv
SELECT
sp.id + 30000 AS id,
sp.smurf_id + 2000 AS field_map_block_id,
p.name + CASE WHEN u.name IS NOT NULL THEN ' ('+u.name+')' ELSE '' END AS name, 
CONVERT(VARCHAR(50), NULL)  AS description,
sp.sort_order AS display_order, 
NULL AS setter,
NULL AS [lookup],
CONVERT(VARCHAR(50), NULL)  AS lookup_service,
1 AS nullable,
CASE WHEN po.property_id IS NOT NULL THEN 12 ELSE 10 END field_map_type_id,
CONVERT(VARCHAR(50), NULL)  AS database_id,
2  AS save_sequence,
CONVERT(VARCHAR(50), NULL)  AS onchange,
CASE WHEN s.class_id = 2 THEN 9 ELSE 12 END
FROM dbo.smurf_property sp
JOIN dbo.smurf s ON sp.smurf_id = s.id
JOIN dbo.property p ON sp.property_id = p.id
LEFT JOIN dbo.unit u ON u.id = p.unit_id
LEFT JOIN dbo.property_option po ON po.property_id = p.id
UNION
-- fatsmurfs for single reading editing
SELECT
sp.id + 40000 AS id,
sp.smurf_id + 3000 AS field_map_block_id,
p.name + CASE WHEN u.name IS NOT NULL THEN ' ('+u.name+')' ELSE '' END AS name, 
CONVERT(VARCHAR(50), NULL)  AS description,
sp.sort_order AS display_order, 
'setPollValueBySpid('+CONVERT(VARCHAR(25), sp.id)+', ?)' AS setter,
CASE WHEN po.property_id IS NULL THEN NULL ELSE 'PropertyPeer::getLookupByPropertyId('+CAST(po.property_id AS VARCHAR(10))+')' END AS [lookup],
CONVERT(VARCHAR(50), NULL)  AS lookup_service,
1 AS nullable,
CASE WHEN po.property_id IS NOT NULL THEN 12 ELSE 10 END field_map_type_id,
CONVERT(VARCHAR(50), NULL)  AS database_id,
2  AS save_sequence,
CONVERT(VARCHAR(50), NULL)  AS onchange,
CASE WHEN s.class_id = 2 THEN 9 ELSE 12 END
FROM dbo.smurf_property sp
JOIN dbo.smurf s ON sp.smurf_id = s.id
JOIN dbo.property p ON sp.property_id = p.id
LEFT JOIN dbo.unit u ON u.id = p.unit_id
LEFT JOIN dbo.property_option po ON po.property_id = p.id

