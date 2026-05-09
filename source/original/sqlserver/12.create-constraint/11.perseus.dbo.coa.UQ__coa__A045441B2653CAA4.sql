USE [perseus]
GO
            
ALTER TABLE [dbo].[coa]
ADD UNIQUE NONCLUSTERED ([name], [goo_type_id]);

