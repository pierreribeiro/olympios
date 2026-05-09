USE [perseus]
GO
            
CREATE TABLE [dbo].[goo_comment](
[id] int IDENTITY(1, 1) NOT NULL,
[goo_id] int NOT NULL,
[added_on] datetime NOT NULL DEFAULT (getdate()),
[added_by] int NOT NULL,
[comment] text COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[category] varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

