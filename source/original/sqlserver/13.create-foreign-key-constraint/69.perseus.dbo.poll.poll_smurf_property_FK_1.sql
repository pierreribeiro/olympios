USE [perseus]
GO
            
ALTER TABLE [dbo].[poll]
ADD CONSTRAINT [poll_smurf_property_FK_1] FOREIGN KEY ([smurf_property_id]) 
REFERENCES [dbo].[smurf_property] ([id]);

