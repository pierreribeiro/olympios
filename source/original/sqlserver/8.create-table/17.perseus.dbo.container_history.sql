USE [perseus]
GO
            
CREATE TABLE [dbo].[container_history](
[id] int IDENTITY(1, 1) NOT NULL,
[history_id] int NOT NULL,
[container_id] int NOT NULL
)
ON [PRIMARY];

