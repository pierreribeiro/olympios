USE [perseus]
GO
            
CREATE TABLE [dbo].[workflow_section](
[id] int IDENTITY(1, 1) NOT NULL,
[workflow_id] int NOT NULL,
[name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[starting_step_id] int NOT NULL
)
ON [PRIMARY];

