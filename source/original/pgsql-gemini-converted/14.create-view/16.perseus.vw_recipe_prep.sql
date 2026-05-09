CREATE VIEW perseus.vw_recipe_prep AS
 SELECT id,
    name,
    material_type_id,
    container_id,
    recipe_id,
    triton_task_id,
    original_volume AS volume_l,
    original_mass AS mass_kg,
    created_on,
    created_by_id
   FROM perseus.vw_lot prep
  WHERE ((recipe_id IS NOT NULL) AND (process_type_id = 207));


ALTER VIEW perseus.vw_recipe_prep OWNER TO perseus_owner;

