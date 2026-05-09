ALTER TABLE ONLY perseus.workflow_section
    ADD CONSTRAINT uq__workflow__7533c67705909073 UNIQUE (workflow_id, starting_step_id);

