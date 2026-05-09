ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT fk_goo_workflow_step FOREIGN KEY (workflow_step_id) REFERENCES perseus.workflow_step(id) ON DELETE SET NULL;

