ALTER TABLE ONLY perseus.goo_history
    ADD CONSTRAINT goo_history_fk_2 FOREIGN KEY (goo_id) REFERENCES perseus.goo(id) ON DELETE CASCADE;

