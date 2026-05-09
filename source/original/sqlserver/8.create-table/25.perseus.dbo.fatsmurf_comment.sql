USE [perseus]
GO
            
CREATE TABLE [dbo].[fatsmurf_comment](
[id] int IDENTITY(1, 1) NOT NULL,
[fatsmurf_id] int NOT NULL,
[added_on] datetime NOT NULL DEFAULT (getdate()),
[added_by] int NOT NULL,
[comment] nvarchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

