ALTER TABLE ONLY perseus.field_map
    ADD CONSTRAINT field_map_field_map_set_fk_1 FOREIGN KEY (field_map_set_id) REFERENCES perseus.field_map_set(id);

