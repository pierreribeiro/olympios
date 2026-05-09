USE [perseus]
GO
            
ALTER TABLE [dbo].[recipe_part]
ADD FOREIGN KEY ([part_recipe_id]) 
REFERENCES [dbo].[recipe] ([id]);

