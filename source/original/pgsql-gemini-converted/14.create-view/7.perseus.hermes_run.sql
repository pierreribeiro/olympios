CREATE VIEW perseus.hermes_run AS
 SELECT r.experiment_id,
    r.local_id AS run_id,
    r.description,
    r.created_on,
    r.strain,
    r.max_yield AS yield,
    r.max_titer AS titer,
    rg.id AS result_goo_id,
    ig.id AS feedstock_goo_id,
    c.id AS container_id,
    r.start_time AS run_on,
    r.stop_time AS duration
   FROM (((hermes.run r
     LEFT JOIN perseus.goo rg ON ((('m'::text || rg.id) = (r.resultant_material)::text)))
     LEFT JOIN perseus.goo ig ON ((('m'::text || ig.id) = (r.feedstock_material)::text)))
     LEFT JOIN perseus.container c ON (((c.uid)::text = (r.tank)::text)))
  WHERE ((((COALESCE(r.feedstock_material, ''::character varying))::text <> ''::text) OR ((COALESCE(r.resultant_material, ''::character varying))::text <> ''::text)) AND ((COALESCE(r.feedstock_material, ''::character varying))::text <> (COALESCE(r.resultant_material, ''::character varying))::text));


ALTER VIEW perseus.hermes_run OWNER TO perseus_owner;

