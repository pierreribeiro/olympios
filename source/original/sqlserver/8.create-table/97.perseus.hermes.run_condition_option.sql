USE [perseus]
GO
            
CREATE TABLE [hermes].[run_condition_option](
[id] int IDENTITY(1, 1) NOT NULL,
[value] numeric(11,3) NULL,
[label] varchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[master_condition_id] int NULL
)
ON [PRIMARY];

