USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory]
ADD FOREIGN KEY ([material_id]) 
REFERENCES [dbo].[goo] ([id]);

