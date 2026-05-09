USE [perseus]
GO
            
CREATE TABLE [dbo].[container_type](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[is_parent] int NOT NULL DEFAULT ((1)),
[is_equipment] int NOT NULL DEFAULT ((0)),
[is_single] int NOT NULL DEFAULT ((1)),
[is_restricted] int NOT NULL DEFAULT ((0)),
[is_gooable] int NOT NULL DEFAULT ((0))
)
ON [PRIMARY];

