USE [perseus]
GO
            
ALTER TABLE [dbo].[material_transition]
ADD CONSTRAINT [FK_material_transition_fatsmurf] FOREIGN KEY ([transition_id]) 
REFERENCES [dbo].[fatsmurf] ([uid])
ON DELETE CASCADE;

