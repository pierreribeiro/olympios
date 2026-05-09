ALTER TABLE ONLY perseus.person
    ADD CONSTRAINT uq_person_domain_id UNIQUE (domain_id);

