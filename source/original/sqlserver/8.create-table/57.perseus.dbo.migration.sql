USE [perseus]
GO
            
CREATE TABLE [dbo].[migration](
[id] int NOT NULL,
[description] varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[created_on] datetime NOT NULL DEFAULT (getdate())
)
ON [PRIMARY];

