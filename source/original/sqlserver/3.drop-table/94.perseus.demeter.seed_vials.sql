USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[demeter].[seed_vials]') AND 
type = N'U')
DROP TABLE [demeter].[seed_vials];

