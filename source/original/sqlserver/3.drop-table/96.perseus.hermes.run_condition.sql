USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[hermes].[run_condition]') AND 
type = N'U')
DROP TABLE [hermes].[run_condition];

