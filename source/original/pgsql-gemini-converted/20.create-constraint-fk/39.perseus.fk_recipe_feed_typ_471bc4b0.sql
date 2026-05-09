ALTER TABLE ONLY perseus.recipe
    ADD CONSTRAINT fk__recipe__feed_typ__471bc4b0 FOREIGN KEY (feed_type_id) REFERENCES perseus.feed_type(id);

