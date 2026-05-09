USE [perseus]
GO
            
CREATE TABLE [hermes].[run_condition](
[id] int IDENTITY(1, 1) NOT NULL,
[default_value] numeric(11,3) NULL,
[condition_set_id] int NULL,
[master_condition_id] int NULL
)
ON [PRIMARY];

