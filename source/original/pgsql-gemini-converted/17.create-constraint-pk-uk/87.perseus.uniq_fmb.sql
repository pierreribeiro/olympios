ALTER TABLE ONLY perseus.field_map_block
    ADD CONSTRAINT uniq_fmb UNIQUE (filter, scope);

