USE [perseus]
GO
            
ALTER TABLE [dbo].[cm_user]
ADD CONSTRAINT [PK_user] PRIMARY KEY CLUSTERED ([user_id]);

