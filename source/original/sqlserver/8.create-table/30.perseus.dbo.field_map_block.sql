USE [perseus]
GO
            
CREATE TABLE [dbo].[field_map_block](
[id] int IDENTITY(1, 1) NOT NULL,
[filter] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[scope] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY];

