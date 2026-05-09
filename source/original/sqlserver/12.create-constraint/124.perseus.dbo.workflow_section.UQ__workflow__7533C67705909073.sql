USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_section]
ADD UNIQUE NONCLUSTERED ([workflow_id], [starting_step_id]);

