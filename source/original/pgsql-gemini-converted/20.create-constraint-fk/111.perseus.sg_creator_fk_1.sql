ALTER TABLE ONLY perseus.smurf_group
    ADD CONSTRAINT sg_creator_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);

