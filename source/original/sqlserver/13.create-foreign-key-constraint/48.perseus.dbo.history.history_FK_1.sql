USE [perseus]
GO
            
ALTER TABLE [dbo].[history]
ADD CONSTRAINT [history_FK_1] FOREIGN KEY ([creator_id]) 
REFERENCES [dbo].[perseus_user] ([id]);

