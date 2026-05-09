ALTER TABLE ONLY perseus.container_history
    ADD CONSTRAINT container_history_fk_1 FOREIGN KEY (history_id) REFERENCES perseus.history(id) ON DELETE CASCADE;

