ALTER TABLE ONLY perseus.goo_type_combine_component
    ADD CONSTRAINT goo_type_combine_component_fk_1 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);

