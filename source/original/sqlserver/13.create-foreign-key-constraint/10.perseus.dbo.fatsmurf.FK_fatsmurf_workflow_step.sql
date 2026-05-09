USE [perseus]
GO
            
ALTER TABLE [dbo].[fatsmurf]
ADD CONSTRAINT [FK_fatsmurf_workflow_step] FOREIGN KEY ([workflow_step_id]) 
REFERENCES [dbo].[workflow_step] ([id])
ON DELETE SET NULL;

