ALTER TABLE ONLY perseus.field_map_display_type
    ADD CONSTRAINT combined_field_map_display_type_fk_3 FOREIGN KEY (display_layout_id) REFERENCES perseus.display_layout(id) ON DELETE CASCADE;

