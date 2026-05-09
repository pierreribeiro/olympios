USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_history]
ADD CONSTRAINT [goo_history_FK_1] FOREIGN KEY ([history_id]) 
REFERENCES [dbo].[history] ([id])
ON DELETE CASCADE;

