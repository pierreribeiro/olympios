USE [perseus]
GO
            
ALTER TABLE [dbo].[field_map_type]
ADD UNIQUE NONCLUSTERED ([name]);

