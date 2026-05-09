ALTER TABLE ONLY perseus.robot_log_read
    ADD CONSTRAINT robot_log_read_fk_2 FOREIGN KEY (property_id) REFERENCES perseus.property(id) ON DELETE CASCADE;

