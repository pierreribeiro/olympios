USE [perseus]
GO
            
ALTER TABLE [dbo].[smurf_property]
ADD CONSTRAINT [smurf_property_FK_1] FOREIGN KEY ([property_id]) 
REFERENCES [dbo].[property] ([id])
ON DELETE CASCADE;

