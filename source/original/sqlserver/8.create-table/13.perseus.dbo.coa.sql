USE [perseus]
GO
            
CREATE TABLE [dbo].[coa](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[goo_type_id] int NOT NULL
)
ON [PRIMARY];

