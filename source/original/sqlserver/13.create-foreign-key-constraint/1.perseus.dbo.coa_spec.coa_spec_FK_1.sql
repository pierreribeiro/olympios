USE [perseus]
GO
            
ALTER TABLE [dbo].[coa_spec]
ADD CONSTRAINT [coa_spec_FK_1] FOREIGN KEY ([coa_id]) 
REFERENCES [dbo].[coa] ([id]);

