ALTER TABLE ONLY perseus.recipe_project_assignment
    ADD CONSTRAINT fk__recipe_pr__recip__0d5f605d FOREIGN KEY (recipe_id) REFERENCES perseus.recipe(id);

