USE [perseus]
GO
            
CREATE TABLE [dbo].[robot_log_error](
[id] int IDENTITY(1, 1) NOT NULL,
[robot_log_id] int NOT NULL,
[error_text] varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

