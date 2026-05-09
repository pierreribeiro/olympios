USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[goo_relationship]') AND 
type = N'V')
DROP VIEW [dbo].[goo_relationship];

