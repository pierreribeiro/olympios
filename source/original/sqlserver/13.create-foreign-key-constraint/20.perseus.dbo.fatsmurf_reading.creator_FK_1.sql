USE [perseus]
GO
            
ALTER TABLE [dbo].[fatsmurf_reading]
ADD CONSTRAINT [creator_FK_1] FOREIGN KEY ([added_by]) 
REFERENCES [dbo].[perseus_user] ([id]);

