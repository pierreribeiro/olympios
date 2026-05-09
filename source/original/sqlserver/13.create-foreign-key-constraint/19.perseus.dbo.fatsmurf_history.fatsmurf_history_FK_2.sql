USE [perseus]
GO
            
ALTER TABLE [dbo].[fatsmurf_history]
ADD CONSTRAINT [fatsmurf_history_FK_2] FOREIGN KEY ([fatsmurf_id]) 
REFERENCES [dbo].[fatsmurf] ([id])
ON DELETE CASCADE;

