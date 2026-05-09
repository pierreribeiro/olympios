USE [perseus]
GO
            
ALTER TABLE [dbo].[material_inventory_threshold_notify_user]
ADD CONSTRAINT [FK_mit_notify_user_user] FOREIGN KEY ([user_id]) 
REFERENCES [dbo].[perseus_user] ([id]);

