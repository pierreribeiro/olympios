USE [perseus]
GO
            
ALTER TABLE [dbo].[submission_entry]
ADD CHECK (([priority]='normal' OR [priority]='urgent'));

