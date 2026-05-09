USE [perseus]
GO
            
ALTER TABLE [dbo].[field_map_display_type]
ADD CONSTRAINT [combined_field_map_display_type_FK_2] FOREIGN KEY ([display_type_id]) 
REFERENCES [dbo].[display_type] ([id])
ON DELETE CASCADE;

