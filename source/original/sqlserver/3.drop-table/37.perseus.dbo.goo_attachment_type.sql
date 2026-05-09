USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[goo_attachment_type]') AND 
type = N'U')
DROP TABLE [dbo].[goo_attachment_type];

