USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_step]
ADD CONSTRAINT [FK_workflow_step_smurf] FOREIGN KEY ([smurf_id]) 
REFERENCES [dbo].[smurf] ([id]);

