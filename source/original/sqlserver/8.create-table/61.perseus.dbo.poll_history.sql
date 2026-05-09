USE [perseus]
GO
            
CREATE TABLE [dbo].[poll_history](
[id] int IDENTITY(1, 1) NOT NULL,
[history_id] int NOT NULL,
[poll_id] int NOT NULL
)
ON [PRIMARY];

