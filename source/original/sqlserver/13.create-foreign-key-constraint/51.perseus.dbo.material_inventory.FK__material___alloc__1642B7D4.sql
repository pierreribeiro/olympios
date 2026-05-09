USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory]
ADD FOREIGN KEY ([allocation_container_id]) 
REFERENCES [dbo].[container] ([id]);

