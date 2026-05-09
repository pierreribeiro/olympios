USE [perseus]
GO
            
CREATE TABLE [dbo].[recipe](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[goo_type_id] int NOT NULL,
[description] varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sop] varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[workflow_id] int NULL,
[added_by] int NOT NULL,
[added_on] datetime NOT NULL,
[is_preferred] bit NOT NULL DEFAULT ((0)),
[QC] bit NOT NULL DEFAULT ((0)),
[is_archived] bit NOT NULL DEFAULT ((0)),
[feed_type_id] int NULL,
[stock_concentration] float(53) NULL,
[sterilization_method] varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inoculant_percent] float(53) NULL,
[post_inoc_volume_ml] float(53) NULL
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

