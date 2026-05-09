USE [perseus]
GO
            
ALTER TABLE [dbo].[material_transition]
ADD CONSTRAINT [FK_material_transition_goo] FOREIGN KEY ([material_id]) 
REFERENCES [dbo].[goo] ([uid])
ON UPDATE CASCADE
ON DELETE CASCADE;

