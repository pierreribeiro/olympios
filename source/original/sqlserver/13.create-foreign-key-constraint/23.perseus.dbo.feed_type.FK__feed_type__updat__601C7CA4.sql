USE [perseus]
GO
            
ALTER TABLE [dbo].[feed_type]
ADD FOREIGN KEY ([updated_by_id]) 
REFERENCES [dbo].[perseus_user] ([id]);

