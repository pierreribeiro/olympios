CREATE INDEX ix_container_type ON perseus.container USING btree (container_type_id) INCLUDE (id, mass);

