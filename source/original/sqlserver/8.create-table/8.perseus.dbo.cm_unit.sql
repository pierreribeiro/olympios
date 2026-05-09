USE [perseus]
GO
            
CREATE TABLE [dbo].[cm_unit](
[id] int NOT NULL,
[description] nvarchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[longname] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dimensions_id] int NULL,
[name] nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[factor] numeric(20,10) NULL,
[offset] numeric(20,10) NULL
)
ON [PRIMARY];

