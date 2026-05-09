USE [perseus]
GO
            
CREATE TABLE [dbo].[material_transition](
[material_id] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[transition_id] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[added_on] datetime NOT NULL DEFAULT (getdate())
)
ON [PRIMARY];

