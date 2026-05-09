ALTER TABLE ONLY perseus.fatsmurf_history
    ADD CONSTRAINT fatsmurf_history_fk_1 FOREIGN KEY (history_id) REFERENCES perseus.history(id) ON DELETE CASCADE;

