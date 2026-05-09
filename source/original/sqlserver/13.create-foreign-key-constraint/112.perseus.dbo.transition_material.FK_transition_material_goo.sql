USE [perseus]
GO
            
ALTER TABLE [dbo].[transition_material]
ADD CONSTRAINT [FK_transition_material_goo] FOREIGN KEY ([material_id]) 
REFERENCES [dbo].[goo] ([uid])
ON UPDATE CASCADE
ON DELETE CASCADE;

