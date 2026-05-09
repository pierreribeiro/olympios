USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[combined_field_map]') AND 
type = N'V')
DROP VIEW [dbo].[combined_field_map];

