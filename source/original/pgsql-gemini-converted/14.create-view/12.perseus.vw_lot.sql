CREATE VIEW perseus.vw_lot AS
 SELECT m.id,
    m.uid,
    m.name,
    m.description,
    m.goo_type_id AS material_type_id,
    p.id AS process_id,
    p.uid AS process_uid,
    p.name AS process_name,
    p.description AS process_description,
    p.smurf_id AS process_type_id,
    p.run_on,
    p.duration,
        CASE
            WHEN (p.container_id IS NOT NULL) THEN p.container_id
            ELSE m.container_id
        END AS container_id,
    m.original_volume,
    m.original_mass,
    m.triton_task_id,
    m.recipe_id,
    m.recipe_part_id,
        CASE
            WHEN (m.manufacturer_id IS NULL) THEN p.organization_id
            ELSE m.manufacturer_id
        END AS manufacturer_id,
    p.themis_sample_id,
    m.catalog_label,
    m.added_on AS created_on,
    m.added_by AS created_by_id
   FROM ((perseus.goo m
     LEFT JOIN perseus.transition_material tm ON (((tm.material_id)::text = (m.uid)::text)))
     LEFT JOIN perseus.fatsmurf p ON (((tm.transition_id)::text = (p.uid)::text)));


ALTER VIEW perseus.vw_lot OWNER TO perseus_owner;

