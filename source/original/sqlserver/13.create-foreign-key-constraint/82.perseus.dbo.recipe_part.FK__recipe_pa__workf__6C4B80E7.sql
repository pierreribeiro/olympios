USE [perseus]
GO
            
ALTER TABLE [dbo].[recipe_part]
ADD FOREIGN KEY ([workflow_step_id]) 
REFERENCES [dbo].[workflow_step] ([id]);

