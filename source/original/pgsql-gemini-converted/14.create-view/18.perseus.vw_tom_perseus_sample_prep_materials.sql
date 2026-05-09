CREATE VIEW perseus.vw_tom_perseus_sample_prep_materials AS
 SELECT ds.end_point AS material_id
   FROM (perseus.goo g
     JOIN perseus.m_downstream ds ON (((ds.start_point)::text = (g.uid)::text)))
  WHERE (g.goo_type_id = ANY (ARRAY[40, 62]))
UNION
 SELECT g_0.uid AS material_id
   FROM perseus.goo g_0
  WHERE (g_0.goo_type_id = ANY (ARRAY[40, 62]));


ALTER VIEW perseus.vw_tom_perseus_sample_prep_materials OWNER TO perseus_owner;

