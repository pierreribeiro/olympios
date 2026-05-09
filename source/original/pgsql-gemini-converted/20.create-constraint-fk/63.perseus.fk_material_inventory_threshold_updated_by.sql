ALTER TABLE ONLY perseus.material_inventory_threshold
    ADD CONSTRAINT fk_material_inventory_threshold_updated_by FOREIGN KEY (updated_by_id) REFERENCES perseus.perseus_user(id);

