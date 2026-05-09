CREATE VIEW perseus.translated AS
 SELECT mt.material_id AS source_material,
    tm.material_id AS destination_material,
    mt.transition_id
   FROM (perseus.material_transition mt
     JOIN perseus.transition_material tm ON (((tm.transition_id)::text = (mt.transition_id)::text)));


ALTER VIEW perseus.translated OWNER TO perseus_owner;

