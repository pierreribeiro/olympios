USE [perseus]
GO
            
ALTER TABLE [dbo].[field_map]
ADD CONSTRAINT [field_map_field_map_set_FK_1] FOREIGN KEY ([field_map_set_id]) 
REFERENCES [dbo].[field_map_set] ([id]);

