USE [perseus]
GO
            
ALTER TABLE [dbo].[property]
ADD UNIQUE NONCLUSTERED ([name], [unit_id]);

