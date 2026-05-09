ALTER TABLE ONLY perseus.robot_log_transfer
    ADD CONSTRAINT fk_robot_log_transfer_source_material_id FOREIGN KEY (source_material_id) REFERENCES perseus.goo(id);

