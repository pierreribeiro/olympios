ALTER TABLE ONLY perseus.container_type_position
    ADD CONSTRAINT uq__containe__32b36f0e29f6a937 UNIQUE (parent_container_type_id, position_name);

