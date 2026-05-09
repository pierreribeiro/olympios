USE [perseus]
GO
            
CREATE TABLE [dbo].[goo](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] varchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_on] datetime NOT NULL DEFAULT (getdate()),
[added_by] int NOT NULL,
[original_volume] float(53) NULL DEFAULT ((0)),
[original_mass] float(53) NULL DEFAULT ((0)),
[goo_type_id] int NOT NULL DEFAULT ((8)),
[manufacturer_id] int NOT NULL DEFAULT ((1)),
[received_on] date NULL,
[uid] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[project_id] smallint NULL,
[container_id] int NULL,
[workflow_step_id] int NULL,
[updated_on] datetime NULL DEFAULT (getdate()),
[inserted_on] datetime NULL DEFAULT (getdate()),
[triton_task_id] int NULL,
[recipe_id] int NULL,
[recipe_part_id] int NULL,
[catalog_label] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY];

