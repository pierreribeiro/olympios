ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk__material___recip__1736dc0d FOREIGN KEY (recipe_id) REFERENCES perseus.recipe(id);

