USE [perseus]
GO
            
CREATE TABLE [dbo].[tmp_messy_links](
[source_transition] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source_name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[destination_transition] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[desitnation_name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[material_id] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
ON [PRIMARY];

