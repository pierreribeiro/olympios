USE [perseus]
GO
            
ALTER TABLE [dbo].[cm_application_group]
ADD CONSTRAINT [PK_cm_application_group] PRIMARY KEY CLUSTERED ([application_group_id]);

