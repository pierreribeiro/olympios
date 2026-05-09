ALTER TABLE ONLY perseus.robot_log_container_sequence
    ADD CONSTRAINT robot_log_container_sequence_fk_3 FOREIGN KEY (robot_log_id) REFERENCES perseus.robot_log(id) ON DELETE CASCADE;

