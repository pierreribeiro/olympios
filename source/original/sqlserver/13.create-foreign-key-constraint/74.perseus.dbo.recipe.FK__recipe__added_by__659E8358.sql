USE [perseus]
GO
            
ALTER TABLE [dbo].[recipe]
ADD FOREIGN KEY ([added_by]) 
REFERENCES [dbo].[perseus_user] ([id]);

