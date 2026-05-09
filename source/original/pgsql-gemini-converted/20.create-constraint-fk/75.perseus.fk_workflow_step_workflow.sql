ALTER TABLE ONLY perseus.workflow_step
    ADD CONSTRAINT fk_workflow_step_workflow FOREIGN KEY (scope_id) REFERENCES perseus.workflow(id) ON DELETE CASCADE;

