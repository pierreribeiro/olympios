CREATE VIEW perseus.vw_fermentation_upstream AS
 WITH RECURSIVE upstream AS (
         SELECT pt.destination_process AS start_point,
            pt.destination_process AS parent,
            pt.destination_process_type AS process_type,
            pt.source_process AS child,
            ('/'::text || (pt.destination_process)::text) AS path,
            1 AS level
           FROM perseus.vw_process_upstream pt
          WHERE (pt.source_process_type = 22)
        UNION ALL
         SELECT r.start_point,
            pt_0.destination_process,
            pt_0.destination_process_type AS process_type,
            pt_0.source_process,
                CASE
                    WHEN (pt_0.destination_process_type = 22) THEN ((r.path || '/'::text) || (pt_0.source_process)::text)
                    ELSE r.path
                END AS path,
                CASE
                    WHEN (pt_0.destination_process_type = 22) THEN (r.level + 1)
                    ELSE r.level
                END AS level
           FROM (perseus.vw_process_upstream pt_0
             JOIN upstream r ON (((pt_0.destination_process)::text = (r.child)::text)))
          WHERE ((pt_0.destination_process)::text <> (pt_0.source_process)::text)
        )
 SELECT start_point,
    child AS end_point,
    path,
    level
   FROM upstream
  WHERE (process_type = 22);


ALTER VIEW perseus.vw_fermentation_upstream OWNER TO perseus_owner;

