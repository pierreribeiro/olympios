USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log_container_sequence]
ADD CONSTRAINT [robot_log_container_sequence_FK_2] FOREIGN KEY ([container_id]) 
REFERENCES [dbo].[container] ([id])
ON DELETE CASCADE;

