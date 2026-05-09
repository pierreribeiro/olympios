USE [perseus]
GO
            
CREATE TABLE [dbo].[history_value](
[id] int IDENTITY(1, 1) NOT NULL,
[history_id] int NOT NULL,
[value] varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY];

