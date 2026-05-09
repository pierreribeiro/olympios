ALTER TABLE ONLY perseus.container_type_position
    ADD CONSTRAINT container_type_position_fk_1 FOREIGN KEY (parent_container_type_id) REFERENCES perseus.container_type(id);

