USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory]
ADD FOREIGN KEY ([recipe_id]) 
REFERENCES [dbo].[recipe] ([id]);

