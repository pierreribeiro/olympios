ALTER TABLE ONLY perseus.robot_log
    ADD CONSTRAINT robot_log_fk_1 FOREIGN KEY (robot_run_id) REFERENCES perseus.robot_run(id);

