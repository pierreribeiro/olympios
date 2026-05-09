ALTER TABLE ONLY perseus.container
    ADD CONSTRAINT container_fk_1 FOREIGN KEY (container_type_id) REFERENCES perseus.container_type(id);

