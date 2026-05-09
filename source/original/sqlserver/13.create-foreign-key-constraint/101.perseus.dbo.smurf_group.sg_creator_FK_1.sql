USE [perseus]
GO
            
ALTER TABLE [dbo].[smurf_group]
ADD CONSTRAINT [sg_creator_FK_1] FOREIGN KEY ([added_by]) 
REFERENCES [dbo].[perseus_user] ([id]);

