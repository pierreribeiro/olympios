USE [perseus]
GO
            
ALTER TABLE [dbo].[submission_entry]
ADD FOREIGN KEY ([prepped_by_id]) 
REFERENCES [dbo].[perseus_user] ([id]);

