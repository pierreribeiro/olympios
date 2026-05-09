USE [perseus]
GO
            
CREATE TABLE [dbo].[field_map_display_type](
[id] int IDENTITY(1, 1) NOT NULL,
[field_map_id] int NOT NULL,
[display_type_id] int NOT NULL,
[display] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[display_layout_id] int NOT NULL DEFAULT ((1)),
[manditory] int NOT NULL DEFAULT ((0))
)
ON [PRIMARY];

