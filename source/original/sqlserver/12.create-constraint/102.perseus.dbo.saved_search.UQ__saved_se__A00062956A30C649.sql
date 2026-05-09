USE [perseus]
GO
            
ALTER TABLE [dbo].[saved_search]
ADD UNIQUE NONCLUSTERED ([name], [added_by]);

