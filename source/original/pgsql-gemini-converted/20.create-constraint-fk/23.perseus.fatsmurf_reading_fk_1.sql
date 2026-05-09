ALTER TABLE ONLY perseus.fatsmurf_reading
    ADD CONSTRAINT fatsmurf_reading_fk_1 FOREIGN KEY (fatsmurf_id) REFERENCES perseus.fatsmurf(id) ON DELETE CASCADE;

