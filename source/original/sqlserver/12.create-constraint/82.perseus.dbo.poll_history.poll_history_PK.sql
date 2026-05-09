USE [perseus]
GO
            
ALTER TABLE [dbo].[poll_history]
ADD CONSTRAINT [poll_history_PK] PRIMARY KEY CLUSTERED ([id]);

