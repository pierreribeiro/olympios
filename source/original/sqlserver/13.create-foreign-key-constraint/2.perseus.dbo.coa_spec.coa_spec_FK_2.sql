USE [perseus]
GO
            
ALTER TABLE [dbo].[coa_spec]
ADD CONSTRAINT [coa_spec_FK_2] FOREIGN KEY ([property_id]) 
REFERENCES [dbo].[property] ([id]);

