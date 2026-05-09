ALTER TABLE ONLY perseus.poll
    ADD CONSTRAINT poll_fatsmurf_reading_fk_1 FOREIGN KEY (fatsmurf_reading_id) REFERENCES perseus.fatsmurf_reading(id) ON DELETE CASCADE;

