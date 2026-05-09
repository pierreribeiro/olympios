USE [perseus]
GO
            
ALTER TABLE [dbo].[field_map_block]
ADD CONSTRAINT [uniq_fmb] UNIQUE NONCLUSTERED ([filter], [scope]);

