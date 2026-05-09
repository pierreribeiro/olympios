CREATE INDEX ix_fsr_for_istd_view ON perseus.fatsmurf_reading USING btree (fatsmurf_id) INCLUDE (id);

