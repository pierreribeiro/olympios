ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk__material___mater__182b0046 FOREIGN KEY (material_id) REFERENCES perseus.goo(id);

