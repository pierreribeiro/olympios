ALTER TABLE ONLY perseus.transition_material
    ADD CONSTRAINT fk_transition_material_goo FOREIGN KEY (material_id) REFERENCES perseus.goo(uid) ON UPDATE CASCADE ON DELETE CASCADE;

