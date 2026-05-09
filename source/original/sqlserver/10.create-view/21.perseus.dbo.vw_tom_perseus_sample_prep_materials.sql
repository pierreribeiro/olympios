USE [perseus]
GO
            
CREATE VIEW vw_tom_perseus_sample_prep_materials AS
  SELECT ds.end_point AS material_id 
    FROM goo g
    JOIN m_downstream ds ON ds.start_point = g.uid
   WHERE g.goo_type_id IN (40, 62)
UNION
  SELECT g.uid AS material_id 
    FROM goo g 
   WHERE g.goo_type_id IN (40, 62)

