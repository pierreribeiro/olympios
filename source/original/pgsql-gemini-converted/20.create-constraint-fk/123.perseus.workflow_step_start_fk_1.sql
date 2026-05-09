ALTER TABLE ONLY perseus.workflow_section
    ADD CONSTRAINT workflow_step_start_fk_1 FOREIGN KEY (starting_step_id) REFERENCES perseus.workflow_step(id);

