USE [perseus]
GO
            
CREATE NONCLUSTERED INDEX [IX_material_inventory_threshold_material_type_id]
    ON [dbo].[material_inventory_threshold] ([material_type_id] ASC);

