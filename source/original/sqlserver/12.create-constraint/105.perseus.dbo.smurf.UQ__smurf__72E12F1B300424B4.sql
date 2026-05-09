USE [perseus]
GO
            
ALTER TABLE [dbo].[smurf]
ADD UNIQUE NONCLUSTERED ([name]);

