USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[history_value]') AND 
type = N'U')
DROP TABLE [dbo].[history_value];

