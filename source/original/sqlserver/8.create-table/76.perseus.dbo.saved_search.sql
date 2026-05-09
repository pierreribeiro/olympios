USE [perseus]
GO
            
CREATE TABLE [dbo].[saved_search](
[id] int IDENTITY(1, 1) NOT NULL,
[class_id] int NULL,
[name] varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[added_on] datetime NOT NULL DEFAULT (getdate()),
[added_by] int NOT NULL,
[is_private] int NOT NULL DEFAULT ((1)),
[include_downstream] int NOT NULL DEFAULT ((0)),
[parameter_string] varchar(2500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
ON [PRIMARY];

