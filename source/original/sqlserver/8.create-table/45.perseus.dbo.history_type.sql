USE [perseus]
GO
            
CREATE TABLE [dbo].[history_type](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[format] varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
ON [PRIMARY];

