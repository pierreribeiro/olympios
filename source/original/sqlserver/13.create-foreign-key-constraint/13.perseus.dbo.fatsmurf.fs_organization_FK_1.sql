USE [perseus]
GO
            
ALTER TABLE [dbo].[fatsmurf]
ADD CONSTRAINT [fs_organization_FK_1] FOREIGN KEY ([organization_id]) 
REFERENCES [dbo].[manufacturer] ([id]);

