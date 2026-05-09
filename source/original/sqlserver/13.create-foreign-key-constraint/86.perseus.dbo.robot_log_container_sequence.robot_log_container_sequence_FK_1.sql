USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log_container_sequence]
ADD CONSTRAINT [robot_log_container_sequence_FK_1] FOREIGN KEY ([sequence_type_id]) 
REFERENCES [dbo].[sequence_type] ([id])
ON DELETE CASCADE;

