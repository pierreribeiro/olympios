USE [perseus]
GO
            
ALTER TABLE [dbo].[goo]
ADD CONSTRAINT [manufacturer_FK_1] FOREIGN KEY ([manufacturer_id]) 
REFERENCES [dbo].[manufacturer] ([id]);

