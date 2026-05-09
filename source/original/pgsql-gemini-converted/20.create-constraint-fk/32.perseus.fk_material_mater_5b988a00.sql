ALTER TABLE ONLY perseus.material_qc
    ADD CONSTRAINT fk__material___mater__5b988a00 FOREIGN KEY (material_id) REFERENCES perseus.goo(id);

