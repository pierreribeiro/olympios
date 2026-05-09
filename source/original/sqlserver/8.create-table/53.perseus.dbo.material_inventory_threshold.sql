USE [perseus]
GO
            
CREATE TABLE [dbo].[material_inventory_threshold](
[id] int IDENTITY(1, 1) NOT NULL,
[material_type_id] int NOT NULL,
[min_item_count] int NULL,
[max_item_count] int NULL,
[min_volume_l] float(53) NULL,
[max_volume_l] float(53) NULL,
[min_mass_kg] float(53) NULL,
[max_mass_kg] float(53) NULL,
[created_by_id] int NOT NULL,
[created_on] datetime2(7) NOT NULL DEFAULT (getdate()),
[updated_by_id] int NULL,
[updated_on] datetime2(7) NULL
)
ON [PRIMARY];

