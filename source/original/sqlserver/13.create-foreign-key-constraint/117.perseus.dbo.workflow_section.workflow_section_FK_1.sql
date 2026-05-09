USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow_section]
ADD CONSTRAINT [workflow_section_FK_1] FOREIGN KEY ([workflow_id]) 
REFERENCES [dbo].[workflow] ([id])
ON DELETE CASCADE;

