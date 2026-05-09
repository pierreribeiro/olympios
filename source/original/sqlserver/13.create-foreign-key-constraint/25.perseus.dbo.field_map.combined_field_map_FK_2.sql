USE [perseus]
GO
            
ALTER TABLE [dbo].[field_map]
ADD CONSTRAINT [combined_field_map_FK_2] FOREIGN KEY ([field_map_type_id]) 
REFERENCES [dbo].[field_map_type] ([id]);

