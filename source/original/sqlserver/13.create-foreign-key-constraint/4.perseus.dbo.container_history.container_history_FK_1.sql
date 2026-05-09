USE [perseus]
GO
            
ALTER TABLE [dbo].[container_history]
ADD CONSTRAINT [container_history_FK_1] FOREIGN KEY ([history_id]) 
REFERENCES [dbo].[history] ([id])
ON DELETE CASCADE;

