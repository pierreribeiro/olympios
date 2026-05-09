USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[vw_processable_logs]') AND 
type = N'V')
DROP VIEW [dbo].[vw_processable_logs];

