USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_step]
ADD CONSTRAINT [FK_workflow_step_goo_type] FOREIGN KEY ([goo_type_id]) 
REFERENCES [dbo].[goo_type] ([id]);

