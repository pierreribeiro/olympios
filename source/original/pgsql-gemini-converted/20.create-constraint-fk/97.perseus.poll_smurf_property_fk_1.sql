ALTER TABLE ONLY perseus.poll
    ADD CONSTRAINT poll_smurf_property_fk_1 FOREIGN KEY (smurf_property_id) REFERENCES perseus.smurf_property(id);

