ALTER TABLE ONLY perseus.goo_type_combine_target
    ADD CONSTRAINT goo_type_combine_target_fk_1 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);

