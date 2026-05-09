USE [perseus]
GO
            
CREATE TABLE [dbo].[material_qc](
[id] int IDENTITY(1, 1) NOT NULL,
[material_id] int NOT NULL,
[entity_type_name] text COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[foreign_entity_id] int NOT NULL,
[qc_process_uid] text COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

