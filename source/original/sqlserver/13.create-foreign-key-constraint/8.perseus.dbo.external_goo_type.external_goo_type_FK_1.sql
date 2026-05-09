USE [perseus]
GO
            
ALTER TABLE [dbo].[external_goo_type]
ADD CONSTRAINT [external_goo_type_FK_1] FOREIGN KEY ([goo_type_id]) 
REFERENCES [dbo].[goo_type] ([id]);

