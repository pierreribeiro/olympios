USE [perseus]
GO
            
CREATE TABLE [dbo].[fatsmurf_history](
[id] int IDENTITY(1, 1) NOT NULL,
[history_id] int NOT NULL,
[fatsmurf_id] int NOT NULL
)
ON [PRIMARY];

