USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[robot_log_transfer]') AND 
type = N'U')
DROP TABLE [dbo].[robot_log_transfer];

