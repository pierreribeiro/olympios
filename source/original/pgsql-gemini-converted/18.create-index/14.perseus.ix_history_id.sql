CREATE INDEX ix_history_id ON perseus.poll_history USING btree (poll_id) INCLUDE (history_id);

