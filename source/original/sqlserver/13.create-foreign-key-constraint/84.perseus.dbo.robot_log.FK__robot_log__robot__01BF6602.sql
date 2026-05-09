USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log]
ADD FOREIGN KEY ([robot_log_type_id]) 
REFERENCES [dbo].[robot_log_type] ([id]);

