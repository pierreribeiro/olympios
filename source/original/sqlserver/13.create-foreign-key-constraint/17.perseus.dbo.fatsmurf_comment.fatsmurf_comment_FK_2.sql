USE [perseus]
GO
            
ALTER TABLE [dbo].[fatsmurf_comment]
ADD CONSTRAINT [fatsmurf_comment_FK_2] FOREIGN KEY ([fatsmurf_id]) 
REFERENCES [dbo].[fatsmurf] ([id])
ON DELETE CASCADE;

