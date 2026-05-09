ALTER TABLE ONLY perseus.workflow_section
    ADD CONSTRAINT uq__workflow__d3897980086cfd1e UNIQUE (workflow_id, name);

