ALTER TABLE ONLY perseus.goo_attachment
    ADD CONSTRAINT goo_attachment_fk_2 FOREIGN KEY (goo_id) REFERENCES perseus.goo(id) ON DELETE CASCADE;

