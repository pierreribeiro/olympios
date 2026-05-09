USE [perseus]
GO
            
ALTER TABLE [dbo].[material_qc]
ADD FOREIGN KEY ([material_id]) 
REFERENCES [dbo].[goo] ([id]);

