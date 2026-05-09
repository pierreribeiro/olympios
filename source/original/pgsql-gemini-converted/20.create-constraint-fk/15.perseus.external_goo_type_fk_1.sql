ALTER TABLE ONLY perseus.external_goo_type
    ADD CONSTRAINT external_goo_type_fk_1 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);

