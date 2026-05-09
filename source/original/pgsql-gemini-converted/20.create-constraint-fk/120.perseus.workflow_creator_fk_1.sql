ALTER TABLE ONLY perseus.workflow
    ADD CONSTRAINT workflow_creator_fk_1 FOREIGN KEY (added_by) REFERENCES perseus.perseus_user(id);

