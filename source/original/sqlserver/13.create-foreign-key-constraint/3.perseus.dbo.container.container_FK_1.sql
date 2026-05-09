USE [perseus]
GO
            
ALTER TABLE [dbo].[container]
ADD CONSTRAINT [container_FK_1] FOREIGN KEY ([container_type_id]) 
REFERENCES [dbo].[container_type] ([id]);

