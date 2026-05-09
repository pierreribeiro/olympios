USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[demeter].[barcodes]') AND 
type = N'U')
DROP TABLE [demeter].[barcodes];

