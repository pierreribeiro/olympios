ALTER TABLE ONLY perseus.feed_type
    ADD CONSTRAINT fk__feed_type__creat__5f28586b FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);

