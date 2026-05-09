USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[sp_move_node]') AND 
type = N'P')
DROP PROCEDURE [dbo].[sp_move_node];

