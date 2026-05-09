USE [perseus]
GO
            
CREATE TABLE [hermes].[run_condition_value](
[id] int IDENTITY(1, 1) NOT NULL,
[value] numeric(11,3) NULL,
[master_condition_id] int NULL,
[updated_on] datetime NULL,
[run_id] int NULL
)
ON [PRIMARY];

