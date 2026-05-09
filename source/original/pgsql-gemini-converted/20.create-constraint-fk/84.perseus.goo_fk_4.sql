ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT goo_fk_4 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);

