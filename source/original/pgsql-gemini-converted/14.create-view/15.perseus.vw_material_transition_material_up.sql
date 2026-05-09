CREATE VIEW perseus.vw_material_transition_material_up AS
 SELECT mt.material_id AS source_uid,
    tm.material_id AS destination_uid,
    tm.transition_id AS transition_uid
   FROM (perseus.transition_material tm
     LEFT JOIN perseus.material_transition mt ON (((tm.transition_id)::text = (mt.transition_id)::text)));


ALTER VIEW perseus.vw_material_transition_material_up OWNER TO perseus_owner;

