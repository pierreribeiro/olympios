USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_type]
ADD CONSTRAINT [UQ__goo_type__72A9F59B39237A9A] UNIQUE NONCLUSTERED ([left_id], [right_id], [scope_id]);

