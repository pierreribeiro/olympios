USE [perseus]
GO
            
CREATE TABLE [dbo].[smurf_goo_type](
[id] int IDENTITY(1, 1) NOT NULL,
[smurf_id] int NOT NULL,
[goo_type_id] int NULL,
[is_input] int NOT NULL DEFAULT ((0))
)
ON [PRIMARY];

