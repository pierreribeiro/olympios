USE [perseus]
GO
            
CREATE TABLE [dbo].[container](
[id] int IDENTITY(1, 1) NOT NULL,
[container_type_id] int NOT NULL,
[name] varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uid] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mass] float(53) NULL,
[left_id] int NOT NULL DEFAULT ((1)),
[right_id] int NOT NULL DEFAULT ((2)),
[scope_id] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL DEFAULT (newid()),
[position_name] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[position_x_coordinate] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[position_y_coordinate] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depth] int NOT NULL DEFAULT ((0)),
[created_on] datetime NULL DEFAULT (getdate())
)
ON [PRIMARY];

