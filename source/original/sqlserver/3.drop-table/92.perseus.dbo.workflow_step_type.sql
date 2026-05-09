USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[workflow_step_type]') AND 
type = N'U')
DROP TABLE [dbo].[workflow_step_type];

