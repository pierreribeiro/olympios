USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[GetTransferCombos]') AND 
type = N'TF')
DROP FUNCTION [dbo].[GetTransferCombos];

