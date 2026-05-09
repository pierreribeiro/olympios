USE [perseus]
GO
            
CREATE TABLE [dbo].[cm_unit_dimensions](
[id] int NOT NULL,
[mass] numeric(10,2) NULL,
[length] numeric(10,2) NULL,
[time] numeric(10,2) NULL,
[electric_current] numeric(10,2) NULL,
[thermodynamic_temperature] numeric(10,2) NULL,
[amount_of_substance] numeric(10,2) NULL,
[luminous_intensity] numeric(10,2) NULL,
[default_unit_id] int NOT NULL,
[name] nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
ON [PRIMARY];

