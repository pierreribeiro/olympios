USE [perseus]
GO
            
CREATE TABLE [dbo].[material_inventory](
[id] int IDENTITY(1, 1) NOT NULL,
[material_id] int NOT NULL,
[location_container_id] int NOT NULL,
[is_active] bit NOT NULL,
[current_volume_l] real NULL,
[current_mass_kg] real NULL,
[created_by_id] int NOT NULL,
[created_on] datetime NULL,
[updated_by_id] int NULL,
[updated_on] datetime NULL,
[allocation_container_id] int NULL,
[recipe_id] int NULL,
[comment] text COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[expiration_date] date NULL
)
ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

