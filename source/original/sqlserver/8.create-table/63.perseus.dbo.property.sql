USE [perseus]
GO
            
CREATE TABLE [dbo].[property](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] varchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[unit_id] int NULL
)
ON [PRIMARY];

