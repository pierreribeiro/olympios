USE [perseus]
GO
            
ALTER TABLE [dbo].[smurf_property]
ADD CONSTRAINT [smurf_property_FK_2] FOREIGN KEY ([smurf_id]) 
REFERENCES [dbo].[smurf] ([id])
ON DELETE CASCADE;

