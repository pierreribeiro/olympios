ALTER TABLE ONLY perseus.robot_run
    ADD CONSTRAINT robot_run_fk_2 FOREIGN KEY (robot_id) REFERENCES perseus.container(id);

