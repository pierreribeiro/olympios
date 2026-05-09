USE [perseus]
GO
            
CREATE VIEW "vw_recipe_prep" AS
SELECT
  prep.id,
  prep.name,
  prep.material_type_id,
  prep.container_id,
  prep.recipe_id,
  prep.triton_task_id,
  prep.original_volume AS volume_L,
  prep.original_mass AS mass_kg,
  prep.created_on,
  prep.created_by_id
FROM
  vw_lot prep
WHERE prep.recipe_id IS NOT NULL
  AND prep.process_type_id = 207

