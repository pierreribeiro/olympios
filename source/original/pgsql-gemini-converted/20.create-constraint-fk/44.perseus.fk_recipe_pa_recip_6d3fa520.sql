ALTER TABLE ONLY perseus.recipe_part
    ADD CONSTRAINT fk__recipe_pa__recip__6d3fa520 FOREIGN KEY (recipe_id) REFERENCES perseus.recipe(id);

