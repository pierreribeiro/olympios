USE [perseus]
GO
            
CREATE TABLE [dbo].[container_type_position](
[id] int IDENTITY(1, 1) NOT NULL,
[parent_container_type_id] int NOT NULL,
[child_container_type_id] int NULL,
[position_name] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[position_x_coordinate] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[position_y_coordinate] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY];

