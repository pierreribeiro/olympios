USE [perseus]
GO
            
ALTER TABLE [dbo].[property_option]
ADD CONSTRAINT [property_option_FK_1] FOREIGN KEY ([property_id]) 
REFERENCES [dbo].[property] ([id]);

