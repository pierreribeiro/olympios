USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[cm_unit_compare]') AND 
type = N'U')
DROP TABLE [dbo].[cm_unit_compare];

