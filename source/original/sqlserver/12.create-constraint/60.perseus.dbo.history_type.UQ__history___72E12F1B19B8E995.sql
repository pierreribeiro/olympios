USE [perseus]
GO
            
ALTER TABLE [dbo].[history_type]
ADD UNIQUE NONCLUSTERED ([name]);

