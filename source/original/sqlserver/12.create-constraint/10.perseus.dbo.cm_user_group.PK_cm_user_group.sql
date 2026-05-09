USE [perseus]
GO
            
ALTER TABLE [dbo].[cm_user_group]
ADD CONSTRAINT [PK_cm_user_group] PRIMARY KEY CLUSTERED ([user_id], [group_id]);

