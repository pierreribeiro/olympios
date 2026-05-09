ALTER TABLE ONLY perseus.goo_comment
    ADD CONSTRAINT goo_comment_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);

