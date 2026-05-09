USE [perseus]
GO
            
CREATE TABLE [dbo].[robot_run](
[id] int IDENTITY(1, 1) NOT NULL,
[robot_id] int NULL,
[name] varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[all_qc_passed] bit NULL,
[all_themis_submitted] bit NULL
)
ON [PRIMARY];

