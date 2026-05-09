USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_attachment]
ADD CONSTRAINT [goo_attachment_FK_2] FOREIGN KEY ([goo_id]) 
REFERENCES [dbo].[goo] ([id])
ON DELETE CASCADE;

