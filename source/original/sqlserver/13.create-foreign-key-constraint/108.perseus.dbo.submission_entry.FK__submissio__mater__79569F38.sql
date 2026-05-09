USE [perseus]
GO
            
ALTER TABLE [dbo].[submission_entry]
ADD FOREIGN KEY ([material_id]) 
REFERENCES [dbo].[goo] ([id]);

