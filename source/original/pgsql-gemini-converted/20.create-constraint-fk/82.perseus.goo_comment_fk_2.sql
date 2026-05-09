ALTER TABLE ONLY perseus.goo_comment
    ADD CONSTRAINT goo_comment_fk_2 FOREIGN KEY (goo_id) REFERENCES perseus.goo(id) ON DELETE CASCADE;

