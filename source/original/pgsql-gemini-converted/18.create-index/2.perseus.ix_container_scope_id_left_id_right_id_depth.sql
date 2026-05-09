CREATE INDEX ix_container_scope_id_left_id_right_id_depth ON perseus.container USING btree (scope_id, left_id, right_id, depth);

