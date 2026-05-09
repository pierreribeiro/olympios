USE [perseus]
GO
            
CREATE VIEW [dbo].[translated] WITH SCHEMABINDING  AS
SELECT mt.material_id AS source_material, tm.material_id AS destination_material, mt.transition_id
FROM dbo.material_transition mt
JOIN dbo.transition_material tm ON tm.transition_id = mt.transition_id

