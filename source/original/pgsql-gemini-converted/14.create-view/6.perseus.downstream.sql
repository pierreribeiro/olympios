CREATE VIEW perseus.downstream AS
 WITH RECURSIVE downstream AS (
         SELECT pt.source_material AS start_point,
            pt.source_material AS parent,
            pt.destination_material AS child,
            '/'::text AS path,
            1 AS level
           FROM perseus.translated pt
        UNION ALL
         SELECT r.start_point,
            pt_0.source_material,
            pt_0.destination_material,
            ((r.path || (r.child)::text) || '/'::text),
            (r.level + 1)
           FROM (perseus.translated pt_0
             JOIN downstream r ON (((pt_0.source_material)::text = (r.child)::text)))
          WHERE ((pt_0.source_material)::text <> (pt_0.destination_material)::text)
        )
 SELECT start_point,
    child AS end_point,
    path,
    level
   FROM downstream;


ALTER VIEW perseus.downstream OWNER TO perseus_owner;

