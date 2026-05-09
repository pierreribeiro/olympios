USE [perseus]
GO
            
CREATE TABLE [hermes].[run_master_condition](
[id] int IDENTITY(1, 1) NOT NULL,
[name] varchar(max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[units] nvarchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] nvarchar(250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[optional_order] int NULL,
[created_on] datetime NULL,
[available_in_view] bit NULL,
[creator_id] int NULL,
[condition_type_id] int NULL,
[active] bit NULL
)
ON [PRIMARY];

