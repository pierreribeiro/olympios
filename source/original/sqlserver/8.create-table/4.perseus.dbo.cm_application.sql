USE [perseus]
GO
            
CREATE TABLE [dbo].[cm_application](
[application_id] int NOT NULL,
[label] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[is_active] tinyint NOT NULL,
[application_group_id] int NULL,
[url] varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[owner_user_id] int NULL,
[jira_id] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY];

