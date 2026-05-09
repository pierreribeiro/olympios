USE [perseus]
GO
            
ALTER TABLE [dbo].[recipe_part]
ADD FOREIGN KEY ([goo_type_id]) 
REFERENCES [dbo].[goo_type] ([id]);

