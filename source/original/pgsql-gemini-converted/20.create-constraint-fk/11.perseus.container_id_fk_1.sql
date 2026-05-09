ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT container_id_fk_1 FOREIGN KEY (container_id) REFERENCES perseus.container(id) ON DELETE SET NULL;

