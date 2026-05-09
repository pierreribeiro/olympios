USE [perseus]
GO
            
ALTER TABLE [dbo].[coa]
ADD CONSTRAINT [coa_FK_1] FOREIGN KEY ([goo_type_id]) 
REFERENCES [dbo].[goo_type] ([id]);

