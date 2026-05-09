ALTER TABLE ONLY perseus.material_inventory_threshold
    ADD CONSTRAINT fk_material_inventory_threshold_material_type FOREIGN KEY (material_type_id) REFERENCES perseus.goo_type(id);

