USE [perseus]
GO
            
ALTER TABLE [dbo].[container_type]
ADD UNIQUE NONCLUSTERED ([name]);

