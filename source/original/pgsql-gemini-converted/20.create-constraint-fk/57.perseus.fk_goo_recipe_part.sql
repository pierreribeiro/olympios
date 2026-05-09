ALTER TABLE ONLY perseus.goo
    ADD CONSTRAINT fk_goo_recipe_part FOREIGN KEY (recipe_part_id) REFERENCES perseus.recipe_part(id);

