CREATE VIEW perseus.material_transition_material AS
 SELECT source_material AS start_point,
    transition_id,
    destination_material AS end_point
   FROM perseus.translated;


ALTER VIEW perseus.material_transition_material OWNER TO perseus_owner;

