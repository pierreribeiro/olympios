USE [perseus]
GO
            
ALTER TABLE [dbo].[field_map_display_type]
ADD UNIQUE NONCLUSTERED ([field_map_id], [display_type_id]);

