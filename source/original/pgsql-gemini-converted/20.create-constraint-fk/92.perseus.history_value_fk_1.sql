ALTER TABLE ONLY perseus.history_value
    ADD CONSTRAINT history_value_fk_1 FOREIGN KEY (history_id) REFERENCES perseus.history(id) ON DELETE CASCADE;

