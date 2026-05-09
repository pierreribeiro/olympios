USE [perseus]
GO
            
ALTER TABLE [dbo].[smurf_goo_type]
ADD CONSTRAINT [smurf_goo_type_FK_2] FOREIGN KEY ([goo_type_id]) 
REFERENCES [dbo].[goo_type] ([id])
ON DELETE CASCADE;

