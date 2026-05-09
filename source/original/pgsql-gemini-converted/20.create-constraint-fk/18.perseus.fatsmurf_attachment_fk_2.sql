ALTER TABLE ONLY perseus.fatsmurf_attachment
    ADD CONSTRAINT fatsmurf_attachment_fk_2 FOREIGN KEY (fatsmurf_id) REFERENCES perseus.fatsmurf(id) ON DELETE CASCADE;

