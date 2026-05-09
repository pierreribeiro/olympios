ALTER TABLE ONLY perseus.robot_log_transfer
    ADD CONSTRAINT robot_log_transfer_fk_1 FOREIGN KEY (robot_log_id) REFERENCES perseus.robot_log(id) ON DELETE CASCADE;

