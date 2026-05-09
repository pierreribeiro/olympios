USE [perseus]
GO
            
ALTER TABLE [dbo].[history_value]
ADD CONSTRAINT [history_value_FK_1] FOREIGN KEY ([history_id]) 
REFERENCES [dbo].[history] ([id])
ON DELETE CASCADE;

