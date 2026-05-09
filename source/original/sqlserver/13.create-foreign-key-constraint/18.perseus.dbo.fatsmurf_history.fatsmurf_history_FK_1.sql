USE [perseus]
GO
            
ALTER TABLE [dbo].[fatsmurf_history]
ADD CONSTRAINT [fatsmurf_history_FK_1] FOREIGN KEY ([history_id]) 
REFERENCES [dbo].[history] ([id])
ON DELETE CASCADE;

