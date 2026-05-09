ALTER TABLE ONLY perseus.smurf_goo_type
    ADD CONSTRAINT smurf_goo_type_fk_2 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id) ON DELETE CASCADE;

