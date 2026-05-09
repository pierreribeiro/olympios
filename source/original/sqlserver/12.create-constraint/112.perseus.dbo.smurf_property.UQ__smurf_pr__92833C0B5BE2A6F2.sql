USE [perseus]
GO
            
ALTER TABLE [dbo].[smurf_property]
ADD CONSTRAINT [UQ__smurf_pr__92833C0B5BE2A6F2] UNIQUE NONCLUSTERED ([property_id], [smurf_id]);

