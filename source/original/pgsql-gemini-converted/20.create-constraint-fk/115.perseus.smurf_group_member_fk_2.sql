ALTER TABLE ONLY perseus.smurf_group_member
    ADD CONSTRAINT smurf_group_member_fk_2 FOREIGN KEY (smurf_group_id) REFERENCES perseus.smurf_group(id) ON DELETE CASCADE;

