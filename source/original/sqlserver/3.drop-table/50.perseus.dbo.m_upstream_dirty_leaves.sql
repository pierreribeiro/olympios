USE [perseus]
GO
            
IF  EXISTS (
SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[m_upstream_dirty_leaves]') AND 
type = N'U')
DROP TABLE [dbo].[m_upstream_dirty_leaves];

