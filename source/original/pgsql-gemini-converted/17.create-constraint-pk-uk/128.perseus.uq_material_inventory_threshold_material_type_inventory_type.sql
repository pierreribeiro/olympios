ALTER TABLE ONLY perseus.material_inventory_threshold
    ADD CONSTRAINT uq_material_inventory_threshold_material_type_inventory_type UNIQUE (material_type_id, inventory_type_id);

