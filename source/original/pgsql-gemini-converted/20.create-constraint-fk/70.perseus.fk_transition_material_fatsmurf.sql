ALTER TABLE ONLY perseus.transition_material
    ADD CONSTRAINT fk_transition_material_fatsmurf FOREIGN KEY (transition_id) REFERENCES perseus.fatsmurf(uid) ON DELETE CASCADE;

