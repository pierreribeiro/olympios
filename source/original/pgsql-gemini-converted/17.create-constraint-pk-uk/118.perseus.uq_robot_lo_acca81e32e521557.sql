ALTER TABLE ONLY perseus.robot_log_container_sequence
    ADD CONSTRAINT uq__robot_lo__acca81e32e521557 UNIQUE (robot_log_id, container_id, sequence_type_id);

