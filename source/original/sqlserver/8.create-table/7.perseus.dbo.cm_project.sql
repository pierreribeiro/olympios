USE [perseus]
GO
            
CREATE TABLE [dbo].[cm_project](
[project_id] smallint NOT NULL,
[label] varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[is_active] bit NOT NULL,
[display_order] smallint NOT NULL,
[group_id] int NULL
)
ON [PRIMARY];

