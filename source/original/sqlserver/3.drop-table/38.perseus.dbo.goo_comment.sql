USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[goo_comment]') AND 
type = N'U')
DROP TABLE [dbo].[goo_comment];

