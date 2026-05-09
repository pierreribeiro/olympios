USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_comment]
ADD CONSTRAINT [goo_comment_FK_1] FOREIGN KEY ([added_by]) 
REFERENCES [dbo].[perseus_user] ([id]);

