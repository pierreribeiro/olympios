USE [perseus]
GO
            
ALTER TABLE [dbo].[submission_entry]
ADD CHECK (([sample_type]='overlay' OR [sample_type]='broth' OR [sample_type]='pellet' OR [sample_type]='none'));

