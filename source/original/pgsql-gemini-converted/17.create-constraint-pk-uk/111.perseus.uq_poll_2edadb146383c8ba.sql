ALTER TABLE ONLY perseus.poll
    ADD CONSTRAINT uq__poll__2edadb146383c8ba UNIQUE (fatsmurf_reading_id, smurf_property_id);

