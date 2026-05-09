ALTER TABLE ONLY perseus.field_map
    ADD CONSTRAINT combined_field_map_fk_1 FOREIGN KEY (field_map_block_id) REFERENCES perseus.field_map_block(id);

