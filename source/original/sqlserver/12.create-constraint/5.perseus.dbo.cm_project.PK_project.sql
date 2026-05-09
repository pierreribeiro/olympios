USE [perseus]
GO
            
ALTER TABLE [dbo].[cm_project]
ADD CONSTRAINT [PK_project] PRIMARY KEY CLUSTERED ([project_id]);

