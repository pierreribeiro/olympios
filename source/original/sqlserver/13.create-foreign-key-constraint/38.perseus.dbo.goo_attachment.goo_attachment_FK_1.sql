USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_attachment]
ADD CONSTRAINT [goo_attachment_FK_1] FOREIGN KEY ([added_by]) 
REFERENCES [dbo].[perseus_user] ([id]);

