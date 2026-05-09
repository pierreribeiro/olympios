USE [perseus]
GO
            
ALTER TABLE [dbo].[submission_entry]
ADD FOREIGN KEY ([submission_id]) 
REFERENCES [dbo].[submission] ([id]);

