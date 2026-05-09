ALTER TABLE ONLY perseus.smurf_property
    ADD CONSTRAINT smurf_property_fk_2 FOREIGN KEY (smurf_id) REFERENCES perseus.smurf(id) ON DELETE CASCADE;

