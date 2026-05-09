ALTER TABLE ONLY perseus.goo_history
    ADD CONSTRAINT goo_history_fk_1 FOREIGN KEY (history_id) REFERENCES perseus.history(id) ON DELETE CASCADE;

