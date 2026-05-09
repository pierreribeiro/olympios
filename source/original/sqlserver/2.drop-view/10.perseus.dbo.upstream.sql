USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[upstream]') AND 
type = N'V')
DROP VIEW [dbo].[upstream];

