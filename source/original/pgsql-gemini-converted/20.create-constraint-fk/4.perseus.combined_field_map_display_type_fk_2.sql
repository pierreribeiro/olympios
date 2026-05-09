ALTER TABLE ONLY perseus.field_map_display_type
    ADD CONSTRAINT combined_field_map_display_type_fk_2 FOREIGN KEY (display_type_id) REFERENCES perseus.display_type(id) ON DELETE CASCADE;

