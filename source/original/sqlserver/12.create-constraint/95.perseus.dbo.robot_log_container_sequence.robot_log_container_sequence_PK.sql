USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log_container_sequence]
ADD CONSTRAINT [robot_log_container_sequence_PK] PRIMARY KEY CLUSTERED ([id]);

