ALTER TABLE ONLY perseus.workflow_step
    ADD CONSTRAINT fk_workflow_step_property FOREIGN KEY (property_id) REFERENCES perseus.property(id);

