ALTER TABLE ONLY perseus.m_upstream
    ADD CONSTRAINT m_upstream_pk PRIMARY KEY (start_point, end_point, path);

