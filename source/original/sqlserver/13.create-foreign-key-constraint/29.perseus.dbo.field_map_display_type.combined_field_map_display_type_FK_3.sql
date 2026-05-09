USE [perseus]
GO
            
ALTER TABLE [dbo].[field_map_display_type]
ADD CONSTRAINT [combined_field_map_display_type_FK_3] FOREIGN KEY ([display_layout_id]) 
REFERENCES [dbo].[display_layout] ([id])
ON DELETE CASCADE;

