USE [perseus]
GO
            
ALTER TABLE [dbo].[fatsmurf_reading]
ADD UNIQUE NONCLUSTERED ([name], [fatsmurf_id]);

