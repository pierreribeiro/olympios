USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log_read]
ADD CONSTRAINT [robot_log_read_FK_2] FOREIGN KEY ([property_id]) 
REFERENCES [dbo].[property] ([id])
ON DELETE CASCADE;

