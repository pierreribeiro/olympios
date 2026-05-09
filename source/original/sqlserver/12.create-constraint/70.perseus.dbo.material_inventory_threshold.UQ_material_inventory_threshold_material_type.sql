USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory_threshold]
ADD CONSTRAINT [UQ_material_inventory_threshold_material_type] UNIQUE NONCLUSTERED ([material_type_id]);

