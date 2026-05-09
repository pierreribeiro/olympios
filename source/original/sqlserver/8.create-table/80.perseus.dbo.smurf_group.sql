USE [perseus]
GO
            
CREATE TABLE [dbo].[smurf_group](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[added_by] int NOT NULL,
[is_public] int NOT NULL DEFAULT ((0))
)
ON [PRIMARY];

