USE [perseus]
GO
            
ALTER TABLE [dbo].[history]
ADD CONSTRAINT [history_FK_2] FOREIGN KEY ([history_type_id]) 
REFERENCES [dbo].[history_type] ([id]);

