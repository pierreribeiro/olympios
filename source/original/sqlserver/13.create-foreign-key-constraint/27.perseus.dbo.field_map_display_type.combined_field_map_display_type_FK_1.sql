USE [perseus]
GO
            
ALTER TABLE [dbo].[field_map_display_type]
ADD CONSTRAINT [combined_field_map_display_type_FK_1] FOREIGN KEY ([field_map_id]) 
REFERENCES [dbo].[field_map] ([id])
ON DELETE CASCADE;

