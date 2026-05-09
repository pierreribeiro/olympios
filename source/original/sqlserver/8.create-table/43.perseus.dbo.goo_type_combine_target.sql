USE [perseus]
GO
            
CREATE TABLE [dbo].[goo_type_combine_target](
[id] int IDENTITY(1, 1) NOT NULL,
[goo_type_id] int NOT NULL,
[sort_order] int NOT NULL
)
ON [PRIMARY];

