USE [perseus]
GO
            
CREATE TABLE [dbo].[goo_type](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[color] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[left_id] int NOT NULL,
[right_id] int NOT NULL,
[scope_id] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[disabled] int NOT NULL DEFAULT ((0)),
[casrn] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[iupac] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depth] int NOT NULL DEFAULT ((0)),
[abbreviation] varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[density_kg_l] float(53) NULL
)
ON [PRIMARY];

