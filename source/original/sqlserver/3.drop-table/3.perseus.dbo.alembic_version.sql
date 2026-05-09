USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[alembic_version]') AND 
type = N'U')
DROP TABLE [dbo].[alembic_version];

