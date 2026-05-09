USE [perseus]
GO
            
ALTER TABLE [dbo].[goo]
ADD CONSTRAINT [fk_goo_recipe_part] FOREIGN KEY ([recipe_part_id]) 
REFERENCES [dbo].[recipe_part] ([id]);

