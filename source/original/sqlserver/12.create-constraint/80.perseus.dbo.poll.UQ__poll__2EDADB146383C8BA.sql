USE [perseus]
GO
            
ALTER TABLE [dbo].[poll]
ADD CONSTRAINT [UQ__poll__2EDADB146383C8BA] UNIQUE NONCLUSTERED ([fatsmurf_reading_id], [smurf_property_id]);

