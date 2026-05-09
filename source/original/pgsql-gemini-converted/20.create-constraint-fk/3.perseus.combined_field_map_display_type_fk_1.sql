ALTER TABLE ONLY perseus.field_map_display_type
    ADD CONSTRAINT combined_field_map_display_type_fk_1 FOREIGN KEY (field_map_id) REFERENCES perseus.field_map(id) ON DELETE CASCADE;

