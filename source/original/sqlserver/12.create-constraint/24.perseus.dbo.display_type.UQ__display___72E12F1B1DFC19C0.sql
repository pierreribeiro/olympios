USE [perseus]
GO
            
ALTER TABLE [dbo].[display_type]
ADD UNIQUE NONCLUSTERED ([name]);

