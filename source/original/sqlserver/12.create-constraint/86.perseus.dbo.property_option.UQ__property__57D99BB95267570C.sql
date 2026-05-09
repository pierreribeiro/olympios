USE [perseus]
GO
            
ALTER TABLE [dbo].[property_option]
ADD UNIQUE NONCLUSTERED ([property_id], [label]);

