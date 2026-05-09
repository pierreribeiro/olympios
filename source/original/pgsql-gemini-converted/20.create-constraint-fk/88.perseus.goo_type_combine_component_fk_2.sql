ALTER TABLE ONLY perseus.goo_type_combine_component
    ADD CONSTRAINT goo_type_combine_component_fk_2 FOREIGN KEY (goo_type_combine_target_id) REFERENCES perseus.goo_type_combine_target(id) ON DELETE CASCADE;

