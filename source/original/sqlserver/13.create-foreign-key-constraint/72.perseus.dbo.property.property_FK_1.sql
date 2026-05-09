USE [perseus]
GO
            
ALTER TABLE [dbo].[property]
ADD CONSTRAINT [property_FK_1] FOREIGN KEY ([unit_id]) 
REFERENCES [dbo].[unit] ([id]);

