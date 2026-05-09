USE [perseus]
GO
            
CREATE TABLE [dbo].[person](
[id] int NOT NULL,
[domain_id] char(32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[km_session_id] char(32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[login] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[name] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[email] varchar(254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_login] datetime NULL,
[is_active] bit NOT NULL DEFAULT ((1))
)
ON [PRIMARY];

