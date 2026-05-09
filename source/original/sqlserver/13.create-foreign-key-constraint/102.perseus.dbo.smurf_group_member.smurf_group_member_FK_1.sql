USE [perseus]
GO
            
ALTER TABLE [dbo].[smurf_group_member]
ADD CONSTRAINT [smurf_group_member_FK_1] FOREIGN KEY ([smurf_id]) 
REFERENCES [dbo].[smurf] ([id])
ON DELETE CASCADE;

