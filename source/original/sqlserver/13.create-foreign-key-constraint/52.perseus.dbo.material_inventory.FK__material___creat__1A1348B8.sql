USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory]
ADD FOREIGN KEY ([created_by_id]) 
REFERENCES [dbo].[perseus_user] ([id]);

