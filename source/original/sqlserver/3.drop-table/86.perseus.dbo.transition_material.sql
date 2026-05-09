USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[transition_material]') AND 
type = N'U')
DROP TABLE [dbo].[transition_material];

