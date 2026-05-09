ALTER TABLE ONLY perseus.workflow_step
    ADD CONSTRAINT fk_workflow_step_goo_type FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);

