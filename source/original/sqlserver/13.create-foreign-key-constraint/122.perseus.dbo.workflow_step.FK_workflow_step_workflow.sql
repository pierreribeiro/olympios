USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_step]
ADD CONSTRAINT [FK_workflow_step_workflow] FOREIGN KEY ([scope_id]) 
REFERENCES [dbo].[workflow] ([id])
ON DELETE CASCADE;

