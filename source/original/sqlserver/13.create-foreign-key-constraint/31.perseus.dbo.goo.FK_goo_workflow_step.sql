USE [perseus]
GO
            
ALTER TABLE [dbo].[goo]
ADD CONSTRAINT [FK_goo_workflow_step] FOREIGN KEY ([workflow_step_id]) 
REFERENCES [dbo].[workflow_step] ([id])
ON DELETE SET NULL;

