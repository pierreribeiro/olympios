USE [perseus]
GO
            
ALTER TABLE [dbo].[external_goo_type]
ADD CONSTRAINT [external_goo_type_FK_2] FOREIGN KEY ([manufacturer_id]) 
REFERENCES [dbo].[manufacturer] ([id]);

