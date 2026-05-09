USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow]
ADD CONSTRAINT [workflow_creator_FK_1] FOREIGN KEY ([added_by]) 
REFERENCES [dbo].[perseus_user] ([id]);

