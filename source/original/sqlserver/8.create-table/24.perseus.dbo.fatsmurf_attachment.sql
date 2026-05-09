USE [perseus]
GO
            
CREATE TABLE [dbo].[fatsmurf_attachment](
[id] int IDENTITY(1, 1) NOT NULL,
[fatsmurf_id] int NOT NULL,
[added_on] datetime NOT NULL DEFAULT (getdate()),
[added_by] int NOT NULL,
[description] text COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attachment_name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attachment_mime_type] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attachment] image NULL
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

