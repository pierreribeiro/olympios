ALTER TABLE ONLY perseus.material_transition
    ADD CONSTRAINT fk_material_transition_fatsmurf FOREIGN KEY (transition_id) REFERENCES perseus.fatsmurf(uid) ON DELETE CASCADE;

