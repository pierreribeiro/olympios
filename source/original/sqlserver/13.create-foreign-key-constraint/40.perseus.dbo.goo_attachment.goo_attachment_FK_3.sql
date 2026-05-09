USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_attachment]
ADD CONSTRAINT [goo_attachment_FK_3] FOREIGN KEY ([goo_attachment_type_id]) 
REFERENCES [dbo].[goo_attachment_type] ([id]);

