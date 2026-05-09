ALTER TABLE ONLY perseus.history
    ADD CONSTRAINT history_fk_2 FOREIGN KEY (history_type_id) REFERENCES perseus.history_type(id);

