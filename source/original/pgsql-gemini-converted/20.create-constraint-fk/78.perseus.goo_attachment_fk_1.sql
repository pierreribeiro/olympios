ALTER TABLE ONLY perseus.goo_attachment
    ADD CONSTRAINT goo_attachment_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);

