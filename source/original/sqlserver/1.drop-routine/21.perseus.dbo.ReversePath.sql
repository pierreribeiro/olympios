USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[ReversePath]') AND 
type = N'FN')
DROP FUNCTION [dbo].[ReversePath];

