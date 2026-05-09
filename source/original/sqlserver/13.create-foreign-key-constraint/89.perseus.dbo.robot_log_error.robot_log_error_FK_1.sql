USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log_error]
ADD CONSTRAINT [robot_log_error_FK_1] FOREIGN KEY ([robot_log_id]) 
REFERENCES [dbo].[robot_log] ([id])
ON DELETE CASCADE;

