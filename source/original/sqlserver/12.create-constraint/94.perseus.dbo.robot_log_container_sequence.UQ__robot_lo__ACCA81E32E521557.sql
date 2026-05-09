USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log_container_sequence]
ADD UNIQUE NONCLUSTERED ([robot_log_id], [container_id], [sequence_type_id]);

