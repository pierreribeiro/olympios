USE [perseus]
GO
            
CREATE TABLE [dbo].[property_option](
[id] int IDENTITY(1, 1) NOT NULL,
[property_id] int NOT NULL,
[value] int NOT NULL,
[label] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[disabled] int NOT NULL DEFAULT ((0))
)
ON [PRIMARY];

