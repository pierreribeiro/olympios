USE [perseus]
GO
            
ALTER TABLE [dbo].[feed_type]
ADD FOREIGN KEY ([added_by]) 
REFERENCES [dbo].[perseus_user] ([id]);

