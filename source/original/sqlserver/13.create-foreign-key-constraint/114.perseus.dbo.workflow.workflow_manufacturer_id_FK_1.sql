USE [perseus]
GO
            
ALTER TABLE [dbo].[workflow]
ADD CONSTRAINT [workflow_manufacturer_id_FK_1] FOREIGN KEY ([manufacturer_id]) 
REFERENCES [dbo].[manufacturer] ([id]);

