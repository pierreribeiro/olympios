USE [perseus]
GO
            
ALTER TABLE [dbo].[submission]
ADD FOREIGN KEY ([submitter_id]) 
REFERENCES [dbo].[perseus_user] ([id]);

