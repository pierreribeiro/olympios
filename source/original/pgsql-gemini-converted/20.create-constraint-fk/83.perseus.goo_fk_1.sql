ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT goo_fk_1 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);

