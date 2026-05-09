USE [perseus]
GO
            
CREATE VIEW [dbo].[vw_process_upstream] WITH SCHEMABINDING  AS

  SELECT tm.transition_id AS source_process,
         mt.transition_id AS destination_process,
         fs.smurf_id AS source_process_type,
         fs2.smurf_id AS destination_process_type,
         mt.material_id AS connecting_material
  FROM dbo.material_transition mt
    JOIN dbo.transition_material tm ON tm.material_id = mt.material_id
    JOIN dbo.fatsmurf fs on mt.transition_id = fs.uid
    JOIN dbo.fatsmurf fs2 on tm.transition_id = fs2.uid

