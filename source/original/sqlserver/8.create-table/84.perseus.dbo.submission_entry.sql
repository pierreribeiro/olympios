USE [perseus]
GO
            
CREATE TABLE [dbo].[submission_entry](
[id] int IDENTITY(1, 1) NOT NULL,
[assay_type_id] int NOT NULL,
[material_id] int NOT NULL,
[status] varchar(19) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[priority] varchar(6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[submission_id] int NOT NULL,
[prepped_by_id] int NULL,
[themis_tray_id] int NULL,
[sample_type] varchar(7) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
ON [PRIMARY];

