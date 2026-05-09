ALTER TABLE ONLY perseus.robot_log_read
    ADD CONSTRAINT fk_robot_log_read_source_material_id FOREIGN KEY (source_material_id) REFERENCES perseus.goo(id);

