USE [perseus]
GO
            
CREATE VIEW "vw_recipe_prep_part" AS
SELECT
  split.id AS id,
  r.id AS recipe_id,
  rp.id AS recipe_part_id,
  prep.id AS prep_id,
  rp.goo_type_id AS expected_material_type_id,
  split.material_type_id AS actual_material_type_id,
  src.id AS source_lot_id,
  split.original_volume AS volume_L,
  split.original_mass AS mass_kg,
  split.created_on,
  split.created_by_id
FROM
  vw_lot split
JOIN vw_lot_edge split_to_prep
  ON split_to_prep.src_lot_id = split.id
JOIN vw_lot prep
  ON prep.id = split_to_prep.dst_lot_id
JOIN vw_lot_edge src_to_split
  ON src_to_split.dst_lot_id = split.id
JOIN vw_lot src
  ON src.id = src_to_split.src_lot_id
JOIN recipe r
  ON r.id = prep.recipe_id
JOIN recipe_part rp
  ON rp.id = split.recipe_part_id AND r.id = rp.recipe_id
WHERE split.recipe_part_id IS NOT NULL
  AND prep.recipe_id IS NOT NULL
  AND split.process_type_id = 110
  AND prep.process_type_id = 207

