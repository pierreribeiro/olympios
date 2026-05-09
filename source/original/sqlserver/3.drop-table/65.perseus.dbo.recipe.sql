USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[recipe]') AND 
type = N'U')
DROP TABLE [dbo].[recipe];

