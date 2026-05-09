USE [perseus]
GO
            
ALTER TABLE [dbo].[container_type_position]
ADD CONSTRAINT [container_type_position_FK_2] FOREIGN KEY ([child_container_type_id]) 
REFERENCES [dbo].[container_type] ([id]);

