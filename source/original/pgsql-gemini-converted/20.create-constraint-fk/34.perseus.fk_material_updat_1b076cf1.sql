ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk__material___updat__1b076cf1 FOREIGN KEY (updated_by_id) REFERENCES perseus.perseus_user(id);

