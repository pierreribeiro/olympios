USE [perseus]
GO
            
ALTER TABLE [dbo].[external_goo_type]
ADD UNIQUE NONCLUSTERED ([external_label], [manufacturer_id]);

