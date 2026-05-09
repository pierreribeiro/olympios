ALTER TABLE ONLY perseus.poll_history
    ADD CONSTRAINT poll_history_fk_2 FOREIGN KEY (poll_id) REFERENCES perseus.poll(id) ON DELETE CASCADE;

