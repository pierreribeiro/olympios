USE [perseus]
GO
            
ALTER TABLE [dbo].[smurf_group_member]
ADD UNIQUE NONCLUSTERED ([smurf_group_id], [smurf_id]);

