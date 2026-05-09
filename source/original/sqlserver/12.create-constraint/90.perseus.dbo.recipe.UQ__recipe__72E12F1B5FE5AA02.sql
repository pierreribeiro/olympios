USE [perseus]
GO
            
ALTER TABLE [dbo].[recipe]
ADD UNIQUE NONCLUSTERED ([name]);

