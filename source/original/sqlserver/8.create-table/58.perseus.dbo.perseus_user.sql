USE [perseus]
GO
            
CREATE TABLE [dbo].[perseus_user](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[domain_id] varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[login] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mail] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[admin] int NOT NULL DEFAULT ((0)),
[super] int NOT NULL DEFAULT ((0)),
[common_id] int NULL,
[manufacturer_id] int NOT NULL DEFAULT ((1))
)
ON [PRIMARY];

