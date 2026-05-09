ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT manufacturer_fk_1 FOREIGN KEY (manufacturer_id) REFERENCES perseus.manufacturer(id);

