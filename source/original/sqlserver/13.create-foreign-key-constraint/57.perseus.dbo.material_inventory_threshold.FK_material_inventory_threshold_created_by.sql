USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory_threshold]
ADD CONSTRAINT [FK_material_inventory_threshold_created_by] FOREIGN KEY ([created_by_id]) 
REFERENCES [dbo].[perseus_user] ([id]);

