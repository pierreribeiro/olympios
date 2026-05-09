ALTER TABLE ONLY perseus.m_downstream
    ADD CONSTRAINT m_downstream_pk PRIMARY KEY (start_point, end_point, path);

