ALTER TABLE ONLY perseus.fatsmurf_comment
    ADD CONSTRAINT fatsmurf_comment_fk_2 FOREIGN KEY (fatsmurf_id) REFERENCES perseus.fatsmurf(id) ON DELETE CASCADE;

