ALTER TABLE ONLY perseus.fatsmurf
    ADD CONSTRAINT fk_fatsmurf_workflow_step FOREIGN KEY (workflow_step_id) REFERENCES perseus.workflow_step(id) ON DELETE SET NULL;

