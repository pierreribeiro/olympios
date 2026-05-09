USE [perseus]
GO
            
ALTER TABLE [dbo].[cm_application]
ADD CONSTRAINT [PK_cm_application] PRIMARY KEY CLUSTERED ([application_id]);

