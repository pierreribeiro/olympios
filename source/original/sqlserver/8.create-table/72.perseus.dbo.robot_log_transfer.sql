USE [perseus]
GO
            
CREATE TABLE [dbo].[robot_log_transfer](
[id] int IDENTITY(1, 1) NOT NULL,
[robot_log_id] int NOT NULL,
[source_barcode] nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[destination_barcode] nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[transfer_time] datetime NULL,
[transfer_volume] varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_position] nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[destination_position] nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[material_type_id] int NULL,
[source_material_id] int NULL,
[destination_material_id] int NULL
)
ON [PRIMARY];

