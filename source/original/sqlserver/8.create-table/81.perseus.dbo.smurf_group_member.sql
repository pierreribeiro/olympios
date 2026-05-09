USE [perseus]
GO
            
CREATE TABLE [dbo].[smurf_group_member](
[id] int IDENTITY(1, 1) NOT NULL,
[smurf_group_id] int NOT NULL,
[smurf_id] int NOT NULL
)
ON [PRIMARY];

