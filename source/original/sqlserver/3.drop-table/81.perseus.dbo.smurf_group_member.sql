USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[smurf_group_member]') AND 
type = N'U')
DROP TABLE [dbo].[smurf_group_member];

