USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_step]
ADD CONSTRAINT [FK_workflow_step_property] FOREIGN KEY ([property_id]) 
REFERENCES [dbo].[property] ([id]);

