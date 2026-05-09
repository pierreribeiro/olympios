USE [perseus]
GO
            
CREATE TABLE [dbo].[Permissions](
[emailAddress] nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[permission] char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
ON [PRIMARY];

