ALTER TABLE ONLY perseus.workflow_section
    ADD CONSTRAINT workflow_section_fk_1 FOREIGN KEY (workflow_id) REFERENCES perseus.workflow(id) ON DELETE CASCADE;

