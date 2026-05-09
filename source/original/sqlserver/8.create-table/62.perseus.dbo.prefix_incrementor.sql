USE [perseus]
GO
            
CREATE TABLE [dbo].[prefix_incrementor](
[prefix] varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[counter] int NOT NULL
)
ON [PRIMARY];

