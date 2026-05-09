ALTER TABLE ONLY perseus.feed_type
    ADD CONSTRAINT fk__feed_type__updat__601c7ca4 FOREIGN KEY (updated_by_id) REFERENCES perseus.perseus_user(id);

