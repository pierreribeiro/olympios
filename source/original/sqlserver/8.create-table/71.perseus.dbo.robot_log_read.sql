USE [perseus]
GO
            
CREATE TABLE [dbo].[robot_log_read](
[id] int IDENTITY(1, 1) NOT NULL,
[robot_log_id] int NOT NULL,
[source_barcode] nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[property_id] int NOT NULL,
[value] varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_position] nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_material_id] int NULL
)
ON [PRIMARY];

