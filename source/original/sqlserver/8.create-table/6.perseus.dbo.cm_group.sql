USE [perseus]
GO
            
CREATE TABLE [dbo].[cm_group](
[group_id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[domain_id] char(32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[is_active] bit NOT NULL,
[last_modified] smalldatetime NOT NULL
)
ON [PRIMARY];

