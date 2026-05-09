USE [perseus]
GO
            
CREATE TABLE [dbo].[robot_log_type](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[auto_process] int NOT NULL,
[destination_container_type_id] int NULL
)
ON [PRIMARY];

