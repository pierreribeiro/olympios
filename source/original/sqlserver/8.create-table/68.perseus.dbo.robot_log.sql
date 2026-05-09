USE [perseus]
GO
            
CREATE TABLE [dbo].[robot_log](
[id] int IDENTITY(1, 1) NOT NULL,
[class_id] int NOT NULL,
[source] varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[created_on] datetime NOT NULL DEFAULT (getdate()),
[log_text] varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[file_name] varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[robot_log_checksum] varchar(32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[started_on] datetime NULL,
[completed_on] datetime NULL,
[loaded_on] datetime NULL,
[loaded] int NOT NULL DEFAULT ((0)),
[loadable] int NOT NULL DEFAULT ((0)),
[robot_run_id] int NULL,
[robot_log_type_id] int NOT NULL
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

