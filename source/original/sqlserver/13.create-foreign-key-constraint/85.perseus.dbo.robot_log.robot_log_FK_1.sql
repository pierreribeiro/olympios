USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log]
ADD CONSTRAINT [robot_log_FK_1] FOREIGN KEY ([robot_run_id]) 
REFERENCES [dbo].[robot_run] ([id]);

