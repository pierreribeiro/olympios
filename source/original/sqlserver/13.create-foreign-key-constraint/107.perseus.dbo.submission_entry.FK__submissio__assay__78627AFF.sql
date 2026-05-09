USE [perseus]
GO
            
ALTER TABLE [dbo].[submission_entry]
ADD FOREIGN KEY ([assay_type_id]) 
REFERENCES [dbo].[smurf] ([id]);

