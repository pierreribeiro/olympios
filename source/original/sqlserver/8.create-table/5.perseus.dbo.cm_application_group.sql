USE [perseus]
GO
            
CREATE TABLE [dbo].[cm_application_group](
[application_group_id] int IDENTITY(1, 1) NOT NULL,
[label] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
ON [PRIMARY];

