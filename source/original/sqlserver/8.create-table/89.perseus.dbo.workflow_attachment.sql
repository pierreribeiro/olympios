USE [perseus]
GO
            
CREATE TABLE [dbo].[workflow_attachment](
[id] int IDENTITY(1, 1) NOT NULL,
[workflow_id] int NOT NULL,
[added_on] datetime NOT NULL DEFAULT (getdate()),
[added_by] int NOT NULL,
[attachment_name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attachment_mime_type] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attachment] varbinary(max) NULL
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

