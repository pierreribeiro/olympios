USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[GetHermesExperiment]') AND 
type = N'FN')
DROP FUNCTION [dbo].[GetHermesExperiment];

