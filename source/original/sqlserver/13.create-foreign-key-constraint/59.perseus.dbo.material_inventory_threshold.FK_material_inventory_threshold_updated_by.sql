USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory_threshold]
ADD CONSTRAINT [FK_material_inventory_threshold_updated_by] FOREIGN KEY ([updated_by_id]) 
REFERENCES [dbo].[perseus_user] ([id]);

