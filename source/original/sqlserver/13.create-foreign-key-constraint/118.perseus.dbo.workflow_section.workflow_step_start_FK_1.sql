USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_section]
ADD CONSTRAINT [workflow_step_start_FK_1] FOREIGN KEY ([starting_step_id]) 
REFERENCES [dbo].[workflow_step] ([id]);

