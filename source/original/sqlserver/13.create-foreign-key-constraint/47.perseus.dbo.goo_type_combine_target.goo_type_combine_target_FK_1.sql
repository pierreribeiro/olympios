USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_type_combine_target]
ADD CONSTRAINT [goo_type_combine_target_FK_1] FOREIGN KEY ([goo_type_id]) 
REFERENCES [dbo].[goo_type] ([id]);

