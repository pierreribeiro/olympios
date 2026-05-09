USE [perseus]
GO
            
ALTER TABLE [dbo].[poll_history]
ADD CONSTRAINT [poll_history_FK_1] FOREIGN KEY ([history_id]) 
REFERENCES [dbo].[history] ([id])
ON DELETE CASCADE;

