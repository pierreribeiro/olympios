USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_type_combine_component]
ADD UNIQUE NONCLUSTERED ([goo_type_combine_target_id], [goo_type_id]);

