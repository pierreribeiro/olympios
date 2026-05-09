USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[hermes_run]') AND 
type = N'V')
DROP VIEW [dbo].[hermes_run];

