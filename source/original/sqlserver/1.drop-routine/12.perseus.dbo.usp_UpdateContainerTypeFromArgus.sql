USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[usp_UpdateContainerTypeFromArgus]') AND 
type = N'P')
DROP PROCEDURE [dbo].[usp_UpdateContainerTypeFromArgus];

