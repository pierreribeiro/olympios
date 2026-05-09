ALTER TABLE ONLY perseus.goo_attachment
    ADD CONSTRAINT goo_attachment_fk_3 FOREIGN KEY (goo_attachment_type_id) REFERENCES perseus.goo_attachment_type(id);

