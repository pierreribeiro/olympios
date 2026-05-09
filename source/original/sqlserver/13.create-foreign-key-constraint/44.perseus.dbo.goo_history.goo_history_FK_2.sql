USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_history]
ADD CONSTRAINT [goo_history_FK_2] FOREIGN KEY ([goo_id]) 
REFERENCES [dbo].[goo] ([id])
ON DELETE CASCADE;

