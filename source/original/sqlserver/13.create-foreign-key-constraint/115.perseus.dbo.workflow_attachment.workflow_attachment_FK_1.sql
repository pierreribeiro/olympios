USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_attachment]
ADD CONSTRAINT [workflow_attachment_FK_1] FOREIGN KEY ([added_by]) 
REFERENCES [dbo].[perseus_user] ([id]);

