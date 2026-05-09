USE [perseus]
GO
            
ALTER TABLE [dbo].[goo_attachment_type]
ADD UNIQUE NONCLUSTERED ([name]);

