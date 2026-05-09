USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory_threshold_notify_user]
ADD CONSTRAINT [FK_mit_notify_user_threshold] FOREIGN KEY ([threshold_id]) 
REFERENCES [dbo].[material_inventory_threshold] ([id])
ON DELETE CASCADE;

