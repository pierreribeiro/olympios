USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[material_transition_material]') AND 
type = N'V')
DROP VIEW [dbo].[material_transition_material];

