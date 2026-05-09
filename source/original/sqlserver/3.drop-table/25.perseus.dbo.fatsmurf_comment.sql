USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[fatsmurf_comment]') AND 
type = N'U')
DROP TABLE [dbo].[fatsmurf_comment];

