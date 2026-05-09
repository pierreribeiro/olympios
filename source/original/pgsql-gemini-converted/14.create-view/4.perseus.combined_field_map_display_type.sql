CREATE VIEW perseus.combined_field_map_display_type AS
 SELECT field_map_display_type.id,
    field_map_display_type.field_map_id,
    field_map_display_type.display_type_id,
    field_map_display_type.display,
    field_map_display_type.display_layout_id,
    field_map_display_type.manditory
   FROM perseus.field_map_display_type
UNION
 SELECT combined_sp_field_map_display_type.id,
    combined_sp_field_map_display_type.field_map_id,
    combined_sp_field_map_display_type.display_type_id,
    combined_sp_field_map_display_type.display,
    combined_sp_field_map_display_type.display_layout_id,
    combined_sp_field_map_display_type.manditory
   FROM perseus.combined_sp_field_map_display_type;


ALTER VIEW perseus.combined_field_map_display_type OWNER TO perseus_owner;

