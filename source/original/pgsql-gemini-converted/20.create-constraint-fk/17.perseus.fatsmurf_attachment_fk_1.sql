ALTER TABLE ONLY perseus.fatsmurf_attachment
    ADD CONSTRAINT fatsmurf_attachment_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);

