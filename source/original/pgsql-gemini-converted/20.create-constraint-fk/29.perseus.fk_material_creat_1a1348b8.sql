ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk__material___creat__1a1348b8 FOREIGN KEY (created_by_id) REFERENCES perseus.perseus_user(id);

