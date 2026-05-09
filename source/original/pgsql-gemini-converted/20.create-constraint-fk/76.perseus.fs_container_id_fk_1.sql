ALTER TABLE ONLY perseus.fatsmurf
    ADD CONSTRAINT fs_container_id_fk_1 FOREIGN KEY (container_id) REFERENCES perseus.container(id) ON DELETE SET NULL;

