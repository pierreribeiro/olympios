ALTER TABLE ONLY perseus.perseus_user
    ADD CONSTRAINT fk__perseus_u__manuf__5e1900da FOREIGN KEY (manufacturer_id) REFERENCES perseus.manufacturer(id);

