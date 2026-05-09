USE [perseus]
GO
            
ALTER TABLE [dbo].[poll]
ADD CONSTRAINT [poll_fatsmurf_reading_FK_1] FOREIGN KEY ([fatsmurf_reading_id]) 
REFERENCES [dbo].[fatsmurf_reading] ([id])
ON DELETE CASCADE;

