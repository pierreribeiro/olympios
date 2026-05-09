USE [perseus]
GO
            
CREATE TABLE [dbo].[recipe_part](
[id] int IDENTITY(1, 1) NOT NULL,
[recipe_id] int NOT NULL,
[description] varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[goo_type_id] int NOT NULL,
[amount] float(53) NOT NULL,
[unit_id] int NOT NULL,
[workflow_step_id] int NULL,
[position] int NULL,
[part_recipe_id] int NULL,
[target_conc_in_media] float(53) NULL,
[target_post_inoc_conc] float(53) NULL
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

