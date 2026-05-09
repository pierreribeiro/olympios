USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[feed_type]') AND 
type = N'U')
DROP TABLE [dbo].[feed_type];

