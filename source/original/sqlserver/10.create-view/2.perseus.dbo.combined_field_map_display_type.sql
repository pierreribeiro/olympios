USE [perseus]
GO
            
-- Display View
CREATE VIEW combined_field_map_display_type AS
SELECT [id]
      ,[field_map_id]
      ,[display_type_id]
      ,[display]
      ,[display_layout_id] 
      ,manditory
      FROM dbo.field_map_display_type
UNION
SELECT * FROM combined_sp_field_map_display_type

