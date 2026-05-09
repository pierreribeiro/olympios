USE [perseus]
GO
            
ALTER TABLE [dbo].[smurf_goo_type]
ADD CONSTRAINT [smurf_goo_type_FK_1] FOREIGN KEY ([smurf_id]) 
REFERENCES [dbo].[smurf] ([id]);

