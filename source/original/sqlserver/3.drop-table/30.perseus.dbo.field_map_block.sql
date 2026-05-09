USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[field_map_block]') AND 
type = N'U')
DROP TABLE [dbo].[field_map_block];

