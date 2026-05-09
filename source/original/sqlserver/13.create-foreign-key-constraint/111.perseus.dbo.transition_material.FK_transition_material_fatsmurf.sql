USE [perseus]
GO
            
ALTER TABLE [dbo].[transition_material]
ADD CONSTRAINT [FK_transition_material_fatsmurf] FOREIGN KEY ([transition_id]) 
REFERENCES [dbo].[fatsmurf] ([uid])
ON DELETE CASCADE;

