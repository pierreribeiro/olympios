ALTER TABLE ONLY perseus.submission_entry
    ADD CONSTRAINT fk__submissio__assay__78627aff FOREIGN KEY (assay_type_id) REFERENCES perseus.smurf(id);

