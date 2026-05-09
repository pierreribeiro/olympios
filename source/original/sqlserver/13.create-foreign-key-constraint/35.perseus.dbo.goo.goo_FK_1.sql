USE [perseus]
GO
            
ALTER TABLE [dbo].[goo]
ADD CONSTRAINT [goo_FK_1] FOREIGN KEY ([goo_type_id]) 
REFERENCES [dbo].[goo_type] ([id]);

