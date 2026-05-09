ALTER TABLE ONLY perseus.robot_log_container_sequence
    ADD CONSTRAINT robot_log_container_sequence_fk_1 FOREIGN KEY (sequence_type_id) REFERENCES perseus.sequence_type(id) ON DELETE CASCADE;

