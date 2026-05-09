USE [perseus]
GO
            
ALTER TABLE [dbo].[saved_search]
ADD CONSTRAINT [saved_search_FK_1] FOREIGN KEY ([added_by]) 
REFERENCES [dbo].[perseus_user] ([id]);

