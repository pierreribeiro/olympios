USE [perseus]
GO
            
ALTER TABLE [dbo].[field_map_display_type_user]
ADD UNIQUE NONCLUSTERED ([user_id], [field_map_display_type_id]);

