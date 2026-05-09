USE [perseus]
GO
            
ALTER TABLE [dbo].[fatsmurf_comment]
ADD CONSTRAINT [fatsmurf_comment_FK_1] FOREIGN KEY ([added_by]) 
REFERENCES [dbo].[perseus_user] ([id]);

