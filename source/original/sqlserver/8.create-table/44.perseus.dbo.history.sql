USE [perseus]
GO
            
CREATE TABLE [dbo].[history](
[id] int IDENTITY(1, 1) NOT NULL,
[history_type_id] int NOT NULL,
[creator_id] int NOT NULL,
[created_on] datetime NOT NULL DEFAULT (getdate())
)
ON [PRIMARY];

