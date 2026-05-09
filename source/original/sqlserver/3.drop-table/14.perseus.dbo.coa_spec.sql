USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[coa_spec]') AND 
type = N'U')
DROP TABLE [dbo].[coa_spec];

