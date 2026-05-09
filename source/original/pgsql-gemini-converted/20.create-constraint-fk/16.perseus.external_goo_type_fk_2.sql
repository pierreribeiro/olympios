ALTER TABLE ONLY perseus.external_goo_type
    ADD CONSTRAINT external_goo_type_fk_2 FOREIGN KEY (manufacturer_id) REFERENCES perseus.manufacturer(id);

