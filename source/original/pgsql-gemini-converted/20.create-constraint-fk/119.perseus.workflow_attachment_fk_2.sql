ALTER TABLE ONLY perseus.workflow_attachment
    ADD CONSTRAINT workflow_attachment_fk_2 FOREIGN KEY (workflow_id) REFERENCES perseus.workflow(id) ON DELETE CASCADE;

