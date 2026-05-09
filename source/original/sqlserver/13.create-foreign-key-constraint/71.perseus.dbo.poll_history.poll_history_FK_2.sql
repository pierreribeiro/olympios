USE [perseus]
GO
            
ALTER TABLE [dbo].[poll_history]
ADD CONSTRAINT [poll_history_FK_2] FOREIGN KEY ([poll_id]) 
REFERENCES [dbo].[poll] ([id])
ON DELETE CASCADE;

