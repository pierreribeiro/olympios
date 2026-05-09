USE [perseus]
GO
            
CREATE TABLE [dbo].[smurf](
[id] int IDENTITY(1, 1) NOT NULL,
[class_id] int NOT NULL,
[name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] varchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[themis_method_id] int NULL,
[disabled] int NOT NULL DEFAULT ((0))
)
ON [PRIMARY];

