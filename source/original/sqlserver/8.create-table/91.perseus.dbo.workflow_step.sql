USE [perseus]
GO
            
CREATE TABLE [dbo].[workflow_step](
[id] int IDENTITY(1, 1) NOT NULL,
[left_id] int NULL,
[right_id] int NULL,
[scope_id] int NOT NULL,
[class_id] int NOT NULL,
[name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[smurf_id] int NULL,
[goo_type_id] int NULL,
[property_id] int NULL,
[label] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[optional] tinyint NOT NULL DEFAULT ((0)),
[goo_amount_unit_id] int NULL DEFAULT ((61)),
[depth] int NULL,
[description] varchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RECIPE_FACTOR] float(53) NULL,
[parent_id] int NULL,
[child_order] int NULL
)
ON [PRIMARY];

