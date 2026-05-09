ALTER TABLE ONLY perseus.coa_spec
    ADD CONSTRAINT coa_spec_fk_2 FOREIGN KEY (property_id) REFERENCES perseus.property(id);

