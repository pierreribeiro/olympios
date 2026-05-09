USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_comment]
ADD CONSTRAINT [goo_comment_FK_2] FOREIGN KEY ([goo_id]) 
REFERENCES [dbo].[goo] ([id])
ON DELETE CASCADE;

