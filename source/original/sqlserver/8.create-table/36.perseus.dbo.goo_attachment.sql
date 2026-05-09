USE [perseus]
GO
            
CREATE TABLE [dbo].[goo_attachment](
[id] int IDENTITY(1, 1) NOT NULL,
[goo_id] int NOT NULL,
[added_on] datetime NOT NULL DEFAULT (getdate()),
[added_by] int NOT NULL,
[description] varchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attachment_name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[attachment_mime_type] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attachment] image NULL,
[goo_attachment_type_id] int NULL
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

