USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[perseus_user]') AND 
type = N'U')
DROP TABLE [dbo].[perseus_user];

