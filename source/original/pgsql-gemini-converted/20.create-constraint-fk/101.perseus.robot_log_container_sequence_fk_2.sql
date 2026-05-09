ALTER TABLE ONLY perseus.robot_log_container_sequence
    ADD CONSTRAINT robot_log_container_sequence_fk_2 FOREIGN KEY (container_id) REFERENCES perseus.container(id) ON DELETE CASCADE;

