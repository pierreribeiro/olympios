ALTER TABLE ONLY perseus.recipe_part
    ADD CONSTRAINT fk__recipe_pa__unit___6b575cae FOREIGN KEY (unit_id) REFERENCES perseus.unit(id);

