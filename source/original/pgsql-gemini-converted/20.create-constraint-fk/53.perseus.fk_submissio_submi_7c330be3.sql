ALTER TABLE ONLY perseus.submission_entry
    ADD CONSTRAINT fk__submissio__submi__7c330be3 FOREIGN KEY (submission_id) REFERENCES perseus.submission(id);

