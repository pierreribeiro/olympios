USE [perseus]
GO
            
CREATE TABLE [dbo].[submission](
[id] int IDENTITY(1, 1) NOT NULL,
[submitter_id] int NOT NULL,
[added_on] datetime NOT NULL,
[label] varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
ON [PRIMARY];

