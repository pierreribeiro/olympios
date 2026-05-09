ALTER TABLE ONLY perseus.property_option
    ADD CONSTRAINT property_option_fk_1 FOREIGN KEY (property_id) REFERENCES perseus.property(id);

