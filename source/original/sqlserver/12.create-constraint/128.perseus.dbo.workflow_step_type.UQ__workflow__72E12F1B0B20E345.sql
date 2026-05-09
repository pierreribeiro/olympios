USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_step_type]
ADD UNIQUE NONCLUSTERED ([name]);

