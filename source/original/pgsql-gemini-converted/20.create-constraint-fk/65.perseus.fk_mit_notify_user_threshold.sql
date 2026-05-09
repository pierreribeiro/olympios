ALTER TABLE ONLY perseus.material_inventory_threshold_notify_user
    ADD CONSTRAINT fk_mit_notify_user_threshold FOREIGN KEY (threshold_id) REFERENCES perseus.material_inventory_threshold(id) ON DELETE CASCADE;

