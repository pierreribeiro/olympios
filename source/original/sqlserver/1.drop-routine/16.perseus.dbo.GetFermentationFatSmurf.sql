USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[GetFermentationFatSmurf]') AND 
type = N'FN')
DROP FUNCTION [dbo].[GetFermentationFatSmurf];

