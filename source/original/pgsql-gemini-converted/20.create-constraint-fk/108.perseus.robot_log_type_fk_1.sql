ALTER TABLE ONLY perseus.robot_log_type
    ADD CONSTRAINT robot_log_type_fk_1 FOREIGN KEY (destination_container_type_id) REFERENCES perseus.container_type(id);

