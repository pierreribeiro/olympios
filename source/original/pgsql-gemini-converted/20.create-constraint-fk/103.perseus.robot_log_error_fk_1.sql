ALTER TABLE ONLY perseus.robot_log_error
    ADD CONSTRAINT robot_log_error_fk_1 FOREIGN KEY (robot_log_id) REFERENCES perseus.robot_log(id) ON DELETE CASCADE;

