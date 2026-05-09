USE [perseus]
GO
            
CREATE TABLE [dbo].[field_map_set](
[id] int NOT NULL,
[tab_group_id] int NULL,
[display_order] int NULL,
[name] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[color] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[size] int NULL
)
ON [PRIMARY];

