ALTER TABLE ONLY perseus.workflow_attachment
    ADD CONSTRAINT workflow_attachment_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);

