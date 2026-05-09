USE [perseus]
GO
            
ALTER TABLE [dbo].[recipe]
ADD FOREIGN KEY ([workflow_id]) 
REFERENCES [dbo].[workflow] ([id]);

