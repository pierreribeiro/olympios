USE [perseus]
GO
            
ALTER TABLE [dbo].[goo]
ADD CONSTRAINT [fk_goo_recipe] FOREIGN KEY ([recipe_id]) 
REFERENCES [dbo].[recipe] ([id]);

