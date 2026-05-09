USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log_read]
ADD CONSTRAINT [FK_robot_log_read_source_material_id] FOREIGN KEY ([source_material_id]) 
REFERENCES [dbo].[goo] ([id]);

