ALTER TABLE ONLY perseus.property
    ADD CONSTRAINT property_fk_1 FOREIGN KEY (unit_id) REFERENCES perseus.unit(id);

