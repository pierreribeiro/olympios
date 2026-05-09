ALTER TABLE ONLY perseus.workflow_step
    ADD CONSTRAINT workflow_step_unit_fk_1 FOREIGN KEY (goo_amount_unit_id) REFERENCES perseus.unit(id);

