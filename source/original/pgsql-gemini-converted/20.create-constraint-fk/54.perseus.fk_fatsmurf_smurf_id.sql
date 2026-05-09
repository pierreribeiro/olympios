ALTER TABLE ONLY perseus.fatsmurf
    ADD CONSTRAINT fk_fatsmurf_smurf_id FOREIGN KEY (smurf_id) REFERENCES perseus.smurf(id);

