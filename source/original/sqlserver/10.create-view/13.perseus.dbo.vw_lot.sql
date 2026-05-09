USE [perseus]
GO
            
CREATE VIEW "vw_lot" AS
SELECT
    m.id,
    m.uid,
    m.name,
    m.description,
    m.goo_type_id AS material_type_id,
    p.id AS process_id,
    p.uid AS process_uid,
    p.name AS process_name,
    p.description AS process_description,
    p.smurf_id as process_type_id,
    p.run_on,
    p.duration,
    CASE WHEN p.container_id IS NOT NULL THEN p.container_id ELSE m.container_id END AS container_id,
    m.original_volume,
    m.original_mass,
    m.triton_task_id,
    m.recipe_id,
    m.recipe_part_id,
    CASE WHEN m.manufacturer_id IS NULL THEN p.organization_id ELSE m.manufacturer_id END AS manufacturer_id,
    p.themis_sample_id,
    m.catalog_label,
    m.added_on AS created_on,
    m.added_by AS created_by_id
FROM goo m
LEFT OUTER JOIN transition_material tm ON tm.material_id = m.uid
LEFT OUTER JOIN fatsmurf p ON tm.transition_id = p.uid;

