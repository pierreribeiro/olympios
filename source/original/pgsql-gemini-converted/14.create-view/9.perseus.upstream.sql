CREATE VIEW perseus.upstream AS
 WITH RECURSIVE upstream AS (
         SELECT pt.destination_material AS start_point,
            pt.destination_material AS parent,
            pt.source_material AS child,
            '/'::text AS path,
            1 AS level
           FROM perseus.translated pt
        UNION ALL
         SELECT r.start_point,
            pt_0.destination_material,
            pt_0.source_material,
            ((r.path || (r.child)::text) || '/'::text),
            (r.level + 1)
           FROM (perseus.translated pt_0
             JOIN upstream r ON (((pt_0.destination_material)::text = (r.child)::text)))
          WHERE ((pt_0.destination_material)::text <> (pt_0.source_material)::text)
        )
 SELECT start_point,
    child AS end_point,
    path,
    level
   FROM upstream;


ALTER VIEW perseus.upstream OWNER TO perseus_owner;

