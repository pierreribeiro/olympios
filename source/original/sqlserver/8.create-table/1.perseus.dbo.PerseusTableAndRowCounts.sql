USE [perseus]
GO
            
CREATE TABLE [dbo].[PerseusTableAndRowCounts](
[TableName] nvarchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Rows] char(11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[updated_on] datetime NOT NULL DEFAULT (getdate())
)
ON [PRIMARY];

