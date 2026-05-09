ALTER TABLE ONLY perseus.container_history
    ADD CONSTRAINT container_history_fk_2 FOREIGN KEY (container_id) REFERENCES perseus.container(id) ON DELETE CASCADE;

