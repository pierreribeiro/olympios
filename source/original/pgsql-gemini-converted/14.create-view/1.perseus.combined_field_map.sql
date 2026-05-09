CREATE VIEW perseus.combined_field_map AS
 SELECT field_map.id,
    field_map.field_map_block_id,
    field_map.name,
    field_map.description,
    field_map.display_order,
    field_map.setter,
    field_map.lookup,
    field_map.lookup_service,
    field_map.nullable,
    field_map.field_map_type_id,
    field_map.database_id,
    field_map.save_sequence,
    field_map.onchange,
    field_map.field_map_set_id
   FROM perseus.field_map
UNION
 SELECT combined_sp_field_map.id,
    combined_sp_field_map.field_map_block_id,
    combined_sp_field_map.name,
    combined_sp_field_map.description,
    combined_sp_field_map.display_order,
    combined_sp_field_map.setter,
    combined_sp_field_map.lookup,
    combined_sp_field_map.lookup_service,
    combined_sp_field_map.nullable,
    combined_sp_field_map.field_map_type_id,
    combined_sp_field_map.database_id,
    combined_sp_field_map.save_sequence,
    combined_sp_field_map.onchange,
    combined_sp_field_map.field_map_set_id
   FROM perseus.combined_sp_field_map;


ALTER VIEW perseus.combined_field_map OWNER TO perseus_owner;

