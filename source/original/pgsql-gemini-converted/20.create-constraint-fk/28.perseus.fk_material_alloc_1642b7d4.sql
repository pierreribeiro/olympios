ALTER TABLE ONLY perseus.material_inventory
    ADD CONSTRAINT fk__material___alloc__1642b7d4 FOREIGN KEY (allocation_container_id) REFERENCES perseus.container(id);

