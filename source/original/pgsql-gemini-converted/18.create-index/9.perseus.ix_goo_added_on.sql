CREATE INDEX ix_goo_added_on ON perseus.goo USING btree (added_on) INCLUDE (uid, container_id);

