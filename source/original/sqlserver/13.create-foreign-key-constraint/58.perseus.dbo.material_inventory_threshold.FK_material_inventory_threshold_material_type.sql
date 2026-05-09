USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory_threshold]
ADD CONSTRAINT [FK_material_inventory_threshold_material_type] FOREIGN KEY ([material_type_id]) 
REFERENCES [dbo].[goo_type] ([id]);

