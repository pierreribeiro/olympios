ALTER TABLE ONLY perseus.smurf_goo_type
    ADD CONSTRAINT smurf_goo_type_fk_1 FOREIGN KEY (smurf_id) REFERENCES perseus.smurf(id);

