USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[display_layout]') AND 
type = N'U')
DROP TABLE [dbo].[display_layout];

