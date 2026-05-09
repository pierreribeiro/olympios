USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory]
ADD UNIQUE NONCLUSTERED ([material_id]);

