USE [perseus]
GO
            
CREATE TABLE [dbo].[m_upstream](
[start_point] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[end_point] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[path] varchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[level] int NOT NULL
)
ON [PRIMARY];

