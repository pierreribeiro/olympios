USE [perseus]
GO
            
ALTER TABLE [dbo].[smurf_group_member]
ADD CONSTRAINT [smurf_group_member_FK_2] FOREIGN KEY ([smurf_group_id]) 
REFERENCES [dbo].[smurf_group] ([id])
ON DELETE CASCADE;

