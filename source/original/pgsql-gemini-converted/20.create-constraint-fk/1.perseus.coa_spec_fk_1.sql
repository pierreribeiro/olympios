ALTER TABLE ONLY perseus.coa_spec
    ADD CONSTRAINT coa_spec_fk_1 FOREIGN KEY (coa_id) REFERENCES perseus.coa(id);

