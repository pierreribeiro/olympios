ALTER TABLE ONLY perseus.perseus_user
    ADD CONSTRAINT fk__perseus_u__manuf__6001494c FOREIGN KEY (manufacturer_id) REFERENCES perseus.manufacturer(id);

