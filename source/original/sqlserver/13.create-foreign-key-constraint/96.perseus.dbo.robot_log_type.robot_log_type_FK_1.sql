USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_log_type]
ADD CONSTRAINT [robot_log_type_FK_1] FOREIGN KEY ([destination_container_type_id]) 
REFERENCES [dbo].[container_type] ([id]);

