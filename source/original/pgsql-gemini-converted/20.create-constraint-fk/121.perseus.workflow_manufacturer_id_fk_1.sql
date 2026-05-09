ALTER TABLE ONLY perseus.workflow
    ADD CONSTRAINT workflow_manufacturer_id_fk_1 FOREIGN KEY (manufacturer_id) REFERENCES perseus.manufacturer(id);

