USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_step_type]
ADD CONSTRAINT [workflow_step_type_PK] PRIMARY KEY CLUSTERED ([id]);

