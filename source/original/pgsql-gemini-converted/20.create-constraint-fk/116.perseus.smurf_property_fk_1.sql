ALTER TABLE ONLY perseus.smurf_property
    ADD CONSTRAINT smurf_property_fk_1 FOREIGN KEY (property_id) REFERENCES perseus.property(id) ON DELETE CASCADE;

