CREATE VIEW perseus.vw_lot_path AS
 SELECT sl.id AS src_lot_id,
    dl.id AS dst_lot_id,
    mu.path,
    mu.level AS length
   FROM ((perseus.m_upstream mu
     JOIN perseus.vw_lot sl ON (((sl.uid)::text = (mu.end_point)::text)))
     JOIN perseus.vw_lot dl ON (((dl.uid)::text = (mu.start_point)::text)));


ALTER VIEW perseus.vw_lot_path OWNER TO perseus_owner;

