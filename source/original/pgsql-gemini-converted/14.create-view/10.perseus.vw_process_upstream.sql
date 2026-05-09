CREATE VIEW perseus.vw_process_upstream AS
 SELECT tm.transition_id AS source_process,
    mt.transition_id AS destination_process,
    fs.smurf_id AS source_process_type,
    fs2.smurf_id AS destination_process_type,
    mt.material_id AS connecting_material
   FROM (((perseus.material_transition mt
     JOIN perseus.transition_material tm ON (((tm.material_id)::text = (mt.material_id)::text)))
     JOIN perseus.fatsmurf fs ON (((mt.transition_id)::text = (fs.uid)::text)))
     JOIN perseus.fatsmurf fs2 ON (((tm.transition_id)::text = (fs2.uid)::text)));


ALTER VIEW perseus.vw_process_upstream OWNER TO perseus_owner;

