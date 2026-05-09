ALTER TABLE ONLY perseus.robot_log
    ADD CONSTRAINT fk__robot_log__robot__01bf6602 FOREIGN KEY (robot_log_type_id) REFERENCES perseus.robot_log_type(id);

