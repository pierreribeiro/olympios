USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[vw_material_transition_material_up]') AND 
type = N'V')
DROP VIEW [dbo].[vw_material_transition_material_up];

