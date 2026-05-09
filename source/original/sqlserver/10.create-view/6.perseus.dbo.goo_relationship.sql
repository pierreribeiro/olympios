USE [perseus]
GO
            
CREATE VIEW goo_relationship AS
SELECT id AS parent, merged_into AS child
FROM goo
WHERE merged_into IS NOT NULL
UNION
SELECT p.id, c.id
FROM goo p
JOIN fatsmurf fs ON fs.goo_id = p.id
JOIN goo c ON c.source_process_id = fs.id
UNION
SELECT i.id, o.id
FROM hermes.run r
JOIN goo i ON i.uid = r.feedstock_material
JOIN goo o ON o.uid = r.resultant_material
WHERE ISNULL(r.feedstock_material, '') != ISNULL(r.resultant_material, '')

