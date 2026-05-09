USE [perseus]
GO
            
-- Field Views
CREATE VIEW combined_field_map AS
SELECT [id]
      ,[field_map_block_id]
      ,[name]
      ,[description]
      ,[display_order]
      ,[setter]
      ,[lookup]
      ,[lookup_service]
      ,[nullable]
      ,[field_map_type_id]
      ,[database_id]
      ,[save_sequence]
      ,[onchange] 
      ,field_map_set_id
      FROM field_map
UNION
SELECT * FROM combined_sp_field_map

