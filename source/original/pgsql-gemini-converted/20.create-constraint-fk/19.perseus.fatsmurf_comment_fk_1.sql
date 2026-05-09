ALTER TABLE ONLY perseus.fatsmurf_comment
    ADD CONSTRAINT fatsmurf_comment_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);

