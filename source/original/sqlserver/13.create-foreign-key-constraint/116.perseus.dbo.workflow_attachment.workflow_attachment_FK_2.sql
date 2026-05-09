USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_attachment]
ADD CONSTRAINT [workflow_attachment_FK_2] FOREIGN KEY ([workflow_id]) 
REFERENCES [dbo].[workflow] ([id])
ON DELETE CASCADE;

