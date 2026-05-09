CREATE VIEW perseus.combined_sp_field_map_display_type AS
 SELECT ((sp.id + 10000) + dl.id) AS id,
    (sp.id + 20000) AS field_map_id,
    dl.id AS display_type_id,
    (('getPollValueBySmurfPropertyId('::text || sp.id) || ')'::text) AS display,
    5 AS display_layout_id,
    0 AS manditory
   FROM ((perseus.smurf_property sp
     JOIN perseus.smurf s ON ((s.id = sp.smurf_id)))
     JOIN perseus.property p ON ((p.id = sp.property_id))),
    perseus.display_layout dl
  WHERE ((sp.disabled = false) AND (dl.id = 1))
UNION
 SELECT ((sp_0.id + 20000) + dl_0.id) AS id,
    (sp_0.id + 20000) AS field_map_id,
    dl_0.id AS display_type_id,
    (('getPollValueBySmurfPropertyId('::text || sp_0.id) || ')'::text) AS display,
    7 AS display_layout_id,
    0 AS manditory
   FROM ((perseus.smurf_property sp_0
     JOIN perseus.smurf s_0 ON ((s_0.id = sp_0.smurf_id)))
     JOIN perseus.property p_0 ON ((p_0.id = sp_0.property_id))),
    perseus.display_layout dl_0
  WHERE ((sp_0.disabled = false) AND (dl_0.id = 7))
UNION
 SELECT ((sp_1.id + 30000) + dl_1.id) AS id,
    (sp_1.id + 30000) AS field_map_id,
    dl_1.id AS display_type_id,
    (('getPollValueStringBySmurfPropertyId('::text || sp_1.id) || ')'::text) AS display,
    7 AS display_layout_id,
    0 AS manditory
   FROM ((perseus.smurf_property sp_1
     JOIN perseus.smurf s_1 ON ((s_1.id = sp_1.smurf_id)))
     JOIN perseus.property p_1 ON ((p_1.id = sp_1.property_id))),
    perseus.display_layout dl_1
  WHERE ((sp_1.disabled = false) AND (dl_1.id = 3))
UNION
 SELECT ((sp_2.id + 40000) + dl_2.id) AS id,
    (sp_2.id + 30000) AS field_map_id,
    dl_2.id AS display_type_id,
    (('getPollValueStringBySmurfPropertyId('::text || sp_2.id) || ')'::text) AS display,
    7 AS display_layout_id,
    0 AS manditory
   FROM ((perseus.smurf_property sp_2
     JOIN perseus.smurf s_2 ON ((s_2.id = sp_2.smurf_id)))
     JOIN perseus.property p_2 ON ((p_2.id = sp_2.property_id))),
    perseus.display_layout dl_2
  WHERE ((sp_2.disabled = false) AND (dl_2.id = 6))
UNION
 SELECT ((sp_3.id + 50000) + dl_3.id) AS id,
    (sp_3.id + 40000) AS field_map_id,
    dl_3.id AS display_type_id,
    (('getPollValueBySmurfPropertyId('::text || sp_3.id) || ')'::text) AS display,
    5 AS display_layout_id,
    0 AS manditory
   FROM ((perseus.smurf_property sp_3
     JOIN perseus.smurf s_3 ON ((s_3.id = sp_3.smurf_id)))
     JOIN perseus.property p_3 ON ((p_3.id = sp_3.property_id))),
    perseus.display_layout dl_3
  WHERE ((sp_3.disabled = false) AND (dl_3.id = 1));


ALTER VIEW perseus.combined_sp_field_map_display_type OWNER TO perseus_owner;

