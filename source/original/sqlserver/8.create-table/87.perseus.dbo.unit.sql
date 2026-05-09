USE [perseus]
GO
            
CREATE TABLE [dbo].[unit](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dimension_id] int NULL,
[factor] float(53) NULL,
[offset] float(53) NULL
)
ON [PRIMARY];

