USE [perseus]
GO
            
ALTER TABLE [dbo].[cm_group]
ADD CONSTRAINT [PK_group] PRIMARY KEY CLUSTERED ([group_id]);

