ALTER TABLE ONLY perseus.submission_entry
    ADD CONSTRAINT fk__submissio__mater__79569f38 FOREIGN KEY (material_id) REFERENCES perseus.goo(id);

