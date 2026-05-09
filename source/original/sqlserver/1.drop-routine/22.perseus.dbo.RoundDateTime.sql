USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[RoundDateTime]') AND 
type = N'FN')
DROP FUNCTION [dbo].[RoundDateTime];

