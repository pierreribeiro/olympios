USE [perseus]
GO
            
ALTER TABLE [dbo].[perseus_user]
ADD UNIQUE NONCLUSTERED ([domain_id]);

