USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory]
ADD FOREIGN KEY ([updated_by_id]) 
REFERENCES [dbo].[perseus_user] ([id]);

