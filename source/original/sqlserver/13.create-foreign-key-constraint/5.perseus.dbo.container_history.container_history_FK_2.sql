USE [perseus]
GO
            
ALTER TABLE [dbo].[container_history]
ADD CONSTRAINT [container_history_FK_2] FOREIGN KEY ([container_id]) 
REFERENCES [dbo].[container] ([id])
ON DELETE CASCADE;

