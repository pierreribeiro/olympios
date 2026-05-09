USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log_transfer]
ADD CONSTRAINT [FK_robot_log_transfer_destination_material_id] FOREIGN KEY ([destination_material_id]) 
REFERENCES [dbo].[goo] ([id]);

