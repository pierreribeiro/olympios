USE [perseus]
GO
            
ALTER TABLE [dbo].[container_type_position]
ADD UNIQUE NONCLUSTERED ([parent_container_type_id], [position_name]);

