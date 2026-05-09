CREATE VIEW perseus.combined_sp_field_map AS
 SELECT (sp.id + 20000) AS id,
    (sp.smurf_id + 1000) AS field_map_block_id,
    ((p.name)::text ||
        CASE
            WHEN (u.name IS NOT NULL) THEN ((' ('::text || (u.name)::text) || ')'::text)
            ELSE ''::text
        END) AS name,
    NULL::character varying(50) AS description,
    sp.sort_order AS display_order,
    (('setPollValueBySpid('::text || sp.id) || ', ?)'::text) AS setter,
        CASE
            WHEN (po.property_id IS NULL) THEN (NULL::character varying)::text
            ELSE (('PropertyPeer::getLookupByPropertyId('::text || po.property_id) || ')'::text)
        END AS lookup,
    NULL::character varying(50) AS lookup_service,
    1 AS nullable,
        CASE
            WHEN (po.property_id IS NOT NULL) THEN 12
            ELSE 10
        END AS field_map_type_id,
    NULL::character varying(50) AS database_id,
    1 AS save_sequence,
    NULL::character varying(50) AS onchange,
        CASE
            WHEN (s.class_id = 2) THEN 9
            ELSE 12
        END AS field_map_set_id
   FROM ((((perseus.smurf_property sp
     JOIN perseus.smurf s ON ((sp.smurf_id = s.id)))
     JOIN perseus.property p ON ((sp.property_id = p.id)))
     LEFT JOIN perseus.unit u ON ((u.id = p.unit_id)))
     LEFT JOIN perseus.property_option po ON ((po.property_id = p.id)))
UNION
 SELECT (sp_0.id + 30000) AS id,
    (sp_0.smurf_id + 2000) AS field_map_block_id,
    ((p_0.name)::text ||
        CASE
            WHEN (u_0.name IS NOT NULL) THEN ((' ('::text || (u_0.name)::text) || ')'::text)
            ELSE ''::text
        END) AS name,
    NULL::character varying(50) AS description,
    sp_0.sort_order AS display_order,
    NULL::text AS setter,
    NULL::text AS lookup,
    NULL::character varying(50) AS lookup_service,
    1 AS nullable,
        CASE
            WHEN (po_0.property_id IS NOT NULL) THEN 12
            ELSE 10
        END AS field_map_type_id,
    NULL::character varying(50) AS database_id,
    2 AS save_sequence,
    NULL::character varying(50) AS onchange,
        CASE
            WHEN (s_0.class_id = 2) THEN 9
            ELSE 12
        END AS field_map_set_id
   FROM ((((perseus.smurf_property sp_0
     JOIN perseus.smurf s_0 ON ((sp_0.smurf_id = s_0.id)))
     JOIN perseus.property p_0 ON ((sp_0.property_id = p_0.id)))
     LEFT JOIN perseus.unit u_0 ON ((u_0.id = p_0.unit_id)))
     LEFT JOIN perseus.property_option po_0 ON ((po_0.property_id = p_0.id)))
UNION
 SELECT (sp_1.id + 40000) AS id,
    (sp_1.smurf_id + 3000) AS field_map_block_id,
    ((p_1.name)::text ||
        CASE
            WHEN (u_1.name IS NOT NULL) THEN ((' ('::text || (u_1.name)::text) || ')'::text)
            ELSE ''::text
        END) AS name,
    NULL::character varying(50) AS description,
    sp_1.sort_order AS display_order,
    (('setPollValueBySpid('::text || sp_1.id) || ', ?)'::text) AS setter,
        CASE
            WHEN (po_1.property_id IS NULL) THEN (NULL::character varying)::text
            ELSE (('PropertyPeer::getLookupByPropertyId('::text || po_1.property_id) || ')'::text)
        END AS lookup,
    NULL::character varying(50) AS lookup_service,
    1 AS nullable,
        CASE
            WHEN (po_1.property_id IS NOT NULL) THEN 12
            ELSE 10
        END AS field_map_type_id,
    NULL::character varying(50) AS database_id,
    2 AS save_sequence,
    NULL::character varying(50) AS onchange,
        CASE
            WHEN (s_1.class_id = 2) THEN 9
            ELSE 12
        END AS field_map_set_id
   FROM ((((perseus.smurf_property sp_1
     JOIN perseus.smurf s_1 ON ((sp_1.smurf_id = s_1.id)))
     JOIN perseus.property p_1 ON ((sp_1.property_id = p_1.id)))
     LEFT JOIN perseus.unit u_1 ON ((u_1.id = p_1.unit_id)))
     LEFT JOIN perseus.property_option po_1 ON ((po_1.property_id = p_1.id)));


ALTER VIEW perseus.combined_sp_field_map OWNER TO perseus_owner;

