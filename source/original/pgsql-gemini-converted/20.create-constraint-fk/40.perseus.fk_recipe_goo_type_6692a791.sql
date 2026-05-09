ALTER TABLE ONLY perseus.recipe
    ADD CONSTRAINT fk__recipe__goo_type__6692a791 FOREIGN KEY (goo_type_id) REFERENCES perseus.goo_type(id);

