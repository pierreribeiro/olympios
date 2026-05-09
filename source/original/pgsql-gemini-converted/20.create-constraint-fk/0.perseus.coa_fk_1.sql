ALTER TABLE ONLY perseus.coa
    ADD CONSTRAINT coa_fk_1 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);

