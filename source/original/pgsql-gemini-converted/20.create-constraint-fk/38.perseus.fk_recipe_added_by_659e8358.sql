ALTER TABLE ONLY perseus.recipe
    ADD CONSTRAINT fk__recipe__added_by__659e8358 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);

