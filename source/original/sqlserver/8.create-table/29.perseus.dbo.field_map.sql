USE [perseus]
GO
            
CREATE TABLE [dbo].[field_map](
[id] int IDENTITY(1, 1) NOT NULL,
[field_map_block_id] int NOT NULL,
[name] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[display_order] int NULL,
[setter] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lookup] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lookup_service] varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nullable] int NULL,
[field_map_type_id] int NOT NULL,
[database_id] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[save_sequence] int NOT NULL,
[onchange] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_map_set_id] int NOT NULL
)
ON [PRIMARY];

