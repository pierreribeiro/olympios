ALTER TABLE ONLY perseus.poll_history
    ADD CONSTRAINT poll_history_fk_1 FOREIGN KEY (history_id) REFERENCES perseus.history(id) ON DELETE CASCADE;

