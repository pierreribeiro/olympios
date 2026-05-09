USE [perseus]
GO
            
ALTER TABLE [dbo].[recipe_part]
ADD FOREIGN KEY ([unit_id]) 
REFERENCES [dbo].[unit] ([id]);

