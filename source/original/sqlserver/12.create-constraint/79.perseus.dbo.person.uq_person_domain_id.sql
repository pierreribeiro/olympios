USE [perseus]
GO
            
ALTER TABLE [dbo].[person]
ADD CONSTRAINT [uq_person_domain_id] UNIQUE NONCLUSTERED ([domain_id]);

