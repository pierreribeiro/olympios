ALTER TABLE ONLY perseus.workflow_step
    ADD CONSTRAINT fk_workflow_step_smurf FOREIGN KEY (smurf_id) REFERENCES perseus.smurf(id);

