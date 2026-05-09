USE [perseus]
GO
            
ALTER TABLE [dbo].[recipe]
ADD FOREIGN KEY ([feed_type_id]) 
REFERENCES [dbo].[feed_type] ([id]);

