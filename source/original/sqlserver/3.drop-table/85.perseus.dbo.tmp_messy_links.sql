USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[tmp_messy_links]') AND 
type = N'U')
DROP TABLE [dbo].[tmp_messy_links];

