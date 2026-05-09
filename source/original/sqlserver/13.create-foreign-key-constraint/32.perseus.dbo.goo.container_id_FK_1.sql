USE [perseus]
GO
            
ALTER TABLE [dbo].[goo]
ADD CONSTRAINT [container_id_FK_1] FOREIGN KEY ([container_id]) 
REFERENCES [dbo].[container] ([id])
ON DELETE SET NULL;

