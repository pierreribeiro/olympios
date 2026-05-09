USE [perseus]
GO
            
CREATE TABLE [dbo].[goo_type_combine_component](
[id] int IDENTITY(1, 1) NOT NULL,
[goo_type_combine_target_id] int NOT NULL,
[goo_type_id] int NOT NULL
)
ON [PRIMARY];

