USE [perseus]
GO
            
CREATE TABLE [dbo].[manufacturer](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[goo_prefix] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY];

