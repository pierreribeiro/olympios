USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory_threshold_notify_user]
ADD CONSTRAINT [PK_material_inventory_threshold_notify_user] PRIMARY KEY CLUSTERED ([threshold_id], [user_id]);

