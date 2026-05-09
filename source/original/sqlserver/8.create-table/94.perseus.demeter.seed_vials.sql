USE [perseus]
GO
            
CREATE TABLE [demeter].[seed_vials](
[id] int IDENTITY(1, 1) NOT NULL,
[strain] nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[clone_id] varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_date] date NULL,
[nat_plating_seedvial] nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nat_plating_48hr_od] nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contamination_testing_notes] nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nr_to_historical] numeric(10,2) NULL,
[pa_to_historical] numeric(10,2) NULL,
[jet_to_historical] numeric(10,2) NULL,
[project] varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[growth_media] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[antibioticos_inventory] int NULL,
[campinas_inventory] int NULL,
[tandl_inventory] int NULL,
[viability_pre_na] varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ssod_to_historical_na] varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uv_fene_to_historical_na] varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[nr_to_historical_na] varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pa_to_historical_na] varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[jet_to_historical_na] varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uv_fene_to_historical] numeric(10,2) NULL
)
ON [PRIMARY];

