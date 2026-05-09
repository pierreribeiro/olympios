USE [perseus]
GO
            
ALTER TABLE [dbo].[fatsmurf_reading]
ADD CONSTRAINT [fatsmurf_reading_FK_1] FOREIGN KEY ([fatsmurf_id]) 
REFERENCES [dbo].[fatsmurf] ([id])
ON DELETE CASCADE;

