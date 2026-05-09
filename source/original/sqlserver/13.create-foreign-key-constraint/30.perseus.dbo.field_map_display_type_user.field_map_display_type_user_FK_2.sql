USE [perseus]
GO
            
ALTER TABLE [dbo].[field_map_display_type_user]
ADD CONSTRAINT [field_map_display_type_user_FK_2] FOREIGN KEY ([user_id]) 
REFERENCES [dbo].[perseus_user] ([id])
ON DELETE CASCADE;

