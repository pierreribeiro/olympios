ALTER TABLE ONLY perseus.recipe_part
    ADD CONSTRAINT fk__recipe_pa__workf__6c4b80e7 FOREIGN KEY (workflow_step_id) REFERENCES perseus.workflow_step(id);

