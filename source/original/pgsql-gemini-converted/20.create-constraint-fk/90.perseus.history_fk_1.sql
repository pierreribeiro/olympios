ALTER TABLE ONLY perseus.history
    ADD CONSTRAINT history_fk_1 FOREIGN KEY (creator_id) REFERENCES perseus.perseus_user(id);

