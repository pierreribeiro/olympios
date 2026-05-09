USE [perseus]
GO
            
-- DROP VIEW [dbo].[vw_material_transition_material_up]

CREATE VIEW [dbo].[vw_material_transition_material_up] WITH SCHEMABINDING  AS

  SELECT mt.material_id AS source_uid,
         tm.material_id AS destination_uid,
         tm.transition_id AS transition_uid
    FROM dbo.transition_material AS tm
	LEFT OUTER JOIN dbo.material_transition mt ON tm.transition_id = mt.transition_id

