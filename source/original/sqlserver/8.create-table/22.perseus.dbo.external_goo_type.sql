USE [perseus]
GO
            
CREATE TABLE [dbo].[external_goo_type](
[id] int IDENTITY(1, 1) NOT NULL,
[goo_type_id] int NOT NULL,
[external_label] varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[manufacturer_id] int NOT NULL
)
ON [PRIMARY];

