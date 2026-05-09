USE [perseus]
GO
            
CREATE TABLE [dbo].[robot_log_container_sequence](
[id] int IDENTITY(1, 1) NOT NULL,
[robot_log_id] int NOT NULL,
[container_id] int NOT NULL,
[sequence_type_id] int NOT NULL,
[processed_on] datetime NULL
)
ON [PRIMARY];

