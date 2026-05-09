USE [perseus]
GO
            
ALTER TABLE [dbo].[display_layout]
ADD UNIQUE NONCLUSTERED ([name]);

