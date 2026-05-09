ALTER TABLE ONLY perseus.material_inventory_threshold
    ADD CONSTRAINT fk_material_inventory_threshold_inventory_type_id FOREIGN KEY (inventory_type_id) REFERENCES perseus.material_inventory_type(id);

