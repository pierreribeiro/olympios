ALTER TABLE ONLY perseus.robot_log_read
    ADD CONSTRAINT robot_log_read_fk_1 FOREIGN KEY (robot_log_id) REFERENCES perseus.robot_log(id) ON DELETE CASCADE;

