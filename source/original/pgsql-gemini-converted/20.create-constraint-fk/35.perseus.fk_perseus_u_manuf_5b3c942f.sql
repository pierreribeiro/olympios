ALTER TABLE ONLY perseus.perseus_user
    ADD CONSTRAINT fk__perseus_u__manuf__5b3c942f FOREIGN KEY (manufacturer_id) REFERENCES perseus.manufacturer(id);

