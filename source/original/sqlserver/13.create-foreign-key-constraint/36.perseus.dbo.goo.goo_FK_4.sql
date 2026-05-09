USE [perseus]
GO
            
ALTER TABLE [dbo].[goo]
ADD CONSTRAINT [goo_FK_4] FOREIGN KEY ([added_by]) 
REFERENCES [dbo].[perseus_user] ([id]);

