USE [perseus]
GO
            
ALTER TABLE [dbo].[recipe]
ADD FOREIGN KEY ([goo_type_id]) 
REFERENCES [dbo].[goo_type] ([id]);

