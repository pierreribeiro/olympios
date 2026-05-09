USE [perseus]
GO
            
CREATE TABLE [dbo].[cm_user](
[user_id] int IDENTITY(1, 1) NOT NULL,
[domain_id] char(32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_active] bit NOT NULL,
[name] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[login] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[object_id] uniqueidentifier NULL
)
ON [PRIMARY];

