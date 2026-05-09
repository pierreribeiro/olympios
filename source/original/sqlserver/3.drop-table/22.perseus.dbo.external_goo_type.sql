USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[external_goo_type]') AND 
type = N'U')
DROP TABLE [dbo].[external_goo_type];

