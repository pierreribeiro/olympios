USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log_container_sequence]
ADD CONSTRAINT [robot_log_container_sequence_FK_3] FOREIGN KEY ([robot_log_id]) 
REFERENCES [dbo].[robot_log] ([id])
ON DELETE CASCADE;

