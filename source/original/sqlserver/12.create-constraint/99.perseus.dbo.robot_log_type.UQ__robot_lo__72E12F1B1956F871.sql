USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log_type]
ADD UNIQUE NONCLUSTERED ([name]);

