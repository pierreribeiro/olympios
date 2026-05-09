USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[material_inventory]') AND 
type = N'U')
DROP TABLE [dbo].[material_inventory];

