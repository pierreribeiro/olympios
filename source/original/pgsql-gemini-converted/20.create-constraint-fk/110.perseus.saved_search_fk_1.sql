ALTER TABLE ONLY perseus.saved_search
    ADD CONSTRAINT saved_search_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);

