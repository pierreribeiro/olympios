ALTER TABLE ONLY perseus.field_map
    ADD CONSTRAINT combined_field_map_fk_2 FOREIGN KEY (field_map_type_id) REFERENCES perseus.field_map_type(id);

