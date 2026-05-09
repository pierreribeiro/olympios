USE [perseus]
GO
            
ALTER TABLE [dbo].[fatsmurf_attachment]
ADD CONSTRAINT [fatsmurf_attachment_FK_2] FOREIGN KEY ([fatsmurf_id]) 
REFERENCES [dbo].[fatsmurf] ([id])
ON DELETE CASCADE;

