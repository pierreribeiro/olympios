USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_step]
ADD CONSTRAINT [workflow_step_PK] PRIMARY KEY CLUSTERED ([id]);

