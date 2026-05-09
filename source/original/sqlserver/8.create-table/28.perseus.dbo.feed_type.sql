USE [perseus]
GO
            
CREATE TABLE [dbo].[feed_type](
[id] int IDENTITY(1, 1) NOT NULL,
[added_by] int NOT NULL,
[updated_by_id] int NULL,
[name] varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] text COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[correction_method] text COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL DEFAULT ('SIMPLE'),
[correction_factor] float(53) NOT NULL DEFAULT ((1.0)),
[disabled] bit NOT NULL DEFAULT ((0)),
[added_on] datetime NOT NULL DEFAULT (getdate()),
[updated_on] datetime NULL DEFAULT (getdate())
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

