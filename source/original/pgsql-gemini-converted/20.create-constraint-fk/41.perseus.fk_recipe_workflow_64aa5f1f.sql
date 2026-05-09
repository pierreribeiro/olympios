ALTER TABLE ONLY perseus.recipe
    ADD CONSTRAINT fk__recipe__workflow__64aa5f1f FOREIGN KEY (workflow_id) REFERENCES perseus.workflow(id);

