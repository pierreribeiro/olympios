USE [perseus]
GO
            
ALTER TABLE [dbo].[coa_spec]
ADD UNIQUE NONCLUSTERED ([coa_id], [property_id]);

