ALTER TABLE ONLY perseus.material_inventory_threshold
    ADD CONSTRAINT fk_material_inventory_threshold_created_by FOREIGN KEY (created_by_id) REFERENCES perseus.perseus_user(id);

