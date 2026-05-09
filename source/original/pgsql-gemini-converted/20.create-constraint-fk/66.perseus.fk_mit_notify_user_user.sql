ALTER TABLE ONLY perseus.material_inventory_threshold_notify_user
    ADD CONSTRAINT fk_mit_notify_user_user FOREIGN KEY (user_id) REFERENCES perseus.perseus_user(id);

