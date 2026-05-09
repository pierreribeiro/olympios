ALTER TABLE ONLY perseus.robot_log_transfer
    ADD CONSTRAINT fk_robot_log_transfer_destination_material_id FOREIGN KEY (destination_material_id) REFERENCES perseus.goo(id);

