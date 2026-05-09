ALTER TABLE ONLY perseus.fatsmurf_history
    ADD CONSTRAINT fatsmurf_history_fk_2 FOREIGN KEY (fatsmurf_id) REFERENCES perseus.fatsmurf(id) ON DELETE CASCADE;

