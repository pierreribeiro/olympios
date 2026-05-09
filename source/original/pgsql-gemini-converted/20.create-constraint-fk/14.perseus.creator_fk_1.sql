ALTER TABLE ONLY perseus.fatsmurf_reading
    ADD CONSTRAINT creator_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);

