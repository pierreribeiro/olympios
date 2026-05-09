USE [perseus]
GO
            
ALTER TABLE [dbo].[fatsmurf_attachment]
ADD CONSTRAINT [fatsmurf_attachment_FK_1] FOREIGN KEY ([added_by]) 
REFERENCES [dbo].[perseus_user] ([id]);

