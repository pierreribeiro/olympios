USE [perseus]
GO
            
ALTER TABLE [dbo].[robot_run]
ADD CONSTRAINT [robot_run_FK_2] FOREIGN KEY ([robot_id]) 
REFERENCES [dbo].[container] ([id]);

