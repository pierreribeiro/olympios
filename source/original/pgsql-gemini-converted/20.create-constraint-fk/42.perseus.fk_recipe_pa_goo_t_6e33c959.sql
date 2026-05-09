ALTER TABLE ONLY perseus.recipe_part
    ADD CONSTRAINT fk__recipe_pa__goo_t__6e33c959 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);

