USE [perseus]
GO
            
CREATE TABLE [dbo].[fatsmurf_reading](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fatsmurf_id] int NOT NULL,
[added_on] datetime NOT NULL DEFAULT (getdate()),
[added_by] int NOT NULL DEFAULT ((1))
)
ON [PRIMARY];

