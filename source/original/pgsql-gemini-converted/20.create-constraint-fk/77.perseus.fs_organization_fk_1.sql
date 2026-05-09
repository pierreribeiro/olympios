ALTER TABLE ONLY perseus.fatsmurf
    ADD CONSTRAINT fs_organization_fk_1 FOREIGN KEY (organization_id) REFERENCES perseus.manufacturer(id);

