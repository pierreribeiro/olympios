ALTER TABLE ONLY perseus.smurf_group_member
    ADD CONSTRAINT smurf_group_member_fk_1 FOREIGN KEY (smurf_id) REFERENCES perseus.smurf(id) ON DELETE CASCADE;

