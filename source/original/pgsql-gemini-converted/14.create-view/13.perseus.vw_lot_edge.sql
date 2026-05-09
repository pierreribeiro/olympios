CREATE VIEW perseus.vw_lot_edge AS
 SELECT sl.id AS src_lot_id,
    dl.id AS dst_lot_id,
    mt.added_on AS created_on
   FROM ((perseus.material_transition mt
     JOIN perseus.vw_lot sl ON (((sl.uid)::text = (mt.material_id)::text)))
     JOIN perseus.vw_lot dl ON (((dl.process_uid)::text = (mt.transition_id)::text)));


ALTER VIEW perseus.vw_lot_edge OWNER TO perseus_owner;

