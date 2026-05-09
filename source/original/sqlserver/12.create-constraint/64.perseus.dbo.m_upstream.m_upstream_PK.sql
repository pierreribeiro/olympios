USE [perseus]
GO
            
ALTER TABLE [dbo].[m_upstream]
ADD CONSTRAINT [m_upstream_PK] PRIMARY KEY CLUSTERED ([start_point], [end_point], [path]);

