USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[submission_entry]') AND 
type = N'U')
DROP TABLE [dbo].[submission_entry];

