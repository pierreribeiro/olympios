ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT fk_goo_recipe FOREIGN KEY (recipe_id) REFERENCES perseus.recipe(id);

