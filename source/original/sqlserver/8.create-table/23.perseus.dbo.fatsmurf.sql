USE [perseus]
GO
            
CREATE TABLE [dbo].[fatsmurf](
[id] int IDENTITY(1, 1) NOT NULL,
[smurf_id] int NOT NULL,
[recycled_bottoms_id] int NULL,
[name] varchar(150) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] varchar(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_on] datetime NOT NULL DEFAULT (getdate()),
[run_on] datetime NULL,
[duration] float(53) NULL,
[added_by] int NOT NULL,
[themis_sample_id] int NULL,
[uid] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[run_complete] AS (case when [duration] IS NULL then getdate() else dateadd(minute,[duration]*(60),[run_on]) end),
[container_id] int NULL,
[organization_id] int NULL DEFAULT ((1)),
[workflow_step_id] int NULL,
[updated_on] datetime NULL DEFAULT (getdate()),
[inserted_on] datetime NULL DEFAULT (getdate()),
[triton_task_id] int NULL
)
ON [PRIMARY];

