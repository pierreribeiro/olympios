USE [perseus]
GO
            
ALTER TABLE [dbo].[m_downstream]
ADD CONSTRAINT [m_downstream_PK] PRIMARY KEY CLUSTERED ([start_point], [end_point], [path]);

