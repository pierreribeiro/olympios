USE [perseus]
GO
            
ALTER TABLE [dbo].[recipe_project_assignment]
ADD FOREIGN KEY ([recipe_id]) 
REFERENCES [dbo].[recipe] ([id]);

