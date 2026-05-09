USE [perseus]
GO
            
ALTER TABLE [dbo].[fatsmurf]
ADD CONSTRAINT [fk_fatsmurf_smurf_id] FOREIGN KEY ([smurf_id]) 
REFERENCES [dbo].[smurf] ([id]);

