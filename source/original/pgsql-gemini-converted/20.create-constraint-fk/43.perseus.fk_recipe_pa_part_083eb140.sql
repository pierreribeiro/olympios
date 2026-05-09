ALTER TABLE ONLY perseus.recipe_part
    ADD CONSTRAINT fk__recipe_pa__part___083eb140 FOREIGN KEY (part_recipe_id) REFERENCES perseus.recipe(id);

