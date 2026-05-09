CREATE VIEW perseus.combined_field_map_block AS
 SELECT field_map_block.id,
    field_map_block.filter,
    field_map_block.scope
   FROM perseus.field_map_block
UNION
 SELECT (smurf.id + 1000) AS id,
    (('isSmurf('::text || smurf.id) || ')'::text) AS filter,
    'FatSmurfReading'::character varying AS scope
   FROM perseus.smurf
UNION
 SELECT (smurf_0.id + 2000) AS id,
    (('isSmurf('::text || smurf_0.id) || ')'::text) AS filter,
    'FatSmurf'::character varying AS scope
   FROM perseus.smurf smurf_0
UNION
 SELECT (smurf_1.id + 3000) AS id,
    (('isSmurfWithOneReading('::text || smurf_1.id) || ')'::text) AS filter,
    'FatSmurf'::character varying AS scope
   FROM perseus.smurf smurf_1;


ALTER VIEW perseus.combined_field_map_block OWNER TO perseus_owner;

