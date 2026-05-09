USE [perseus]
GO
            
ALTER TABLE [dbo].[submission_entry]
ADD CONSTRAINT [CK__submissio__statu__7A4AC371] CHECK (([status]='prepped' OR [status]='submitted_to_themis' OR [status]='prepping' OR [status]='error' OR [status]='to_be_prepped' OR [status]='rejected'));

