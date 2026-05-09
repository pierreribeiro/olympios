USE [perseus]
GO
            
CREATE TABLE [dbo].[workflow](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[added_on] datetime NOT NULL DEFAULT (getdate()),
[added_by] int NOT NULL DEFAULT ((23)),
[disabled] int NOT NULL DEFAULT ((0)),
[manufacturer_id] int NOT NULL,
[description] varchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY];

