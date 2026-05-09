USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[combined_sp_field_map_display_type]') AND 
type = N'V')
DROP VIEW [dbo].[combined_sp_field_map_display_type];

