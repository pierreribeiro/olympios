ALTER TABLE ONLY perseus.submission_entry
    ADD CONSTRAINT fk__submissio__prepp__7d27301c FOREIGN KEY (prepped_by_id) REFERENCES perseus.perseus_user(id);

