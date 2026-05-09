USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[hermes].[run]') AND 
type = N'U')
DROP TABLE [hermes].[run];

