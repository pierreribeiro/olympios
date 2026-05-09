USE [perseus]
GO
            
CREATE TABLE [hermes].[run_master_condition_type](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[optional_order] int NULL
)
ON [PRIMARY];

