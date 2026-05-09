ALTER TABLE ONLY perseus.submission
    ADD CONSTRAINT fk__submissio__submi__739dc5e2 FOREIGN KEY (submitter_id) REFERENCES perseus.perseus_user(id);

