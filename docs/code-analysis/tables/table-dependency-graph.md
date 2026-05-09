# Table Dependency Graph - Perseus Database Migration

## Executive Summary

**Analysis Date:** 2026-02-10
**Analyst:** Claude (Database Expert Agent) + Pierre Ribeiro
**Scope:** 92 dbo tables + 8 FDW tables + 1 utility table = 101 tables total
**Foreign Key Constraints:** 124 FK relationships analyzed

---

## Schema Distribution

| Schema | Table Count | FK Constraints | Notes |
|--------|-------------|----------------|-------|
| **dbo** | 92 | 124 | Core Perseus tables (91 main + 1 utility) |
| **hermes** | 6 | 0 | FDW - Experiment/fermentation data |
| **demeter** | 2 | 0 | FDW - Seed vial tracking |
| **TOTAL** | **101** | **124** | Complete database schema |

---

## Tier Classification (Topological Sort)

Tables are classified into 8 dependency tiers (0-7) based on foreign key relationships using topological sorting:
- **Tier 0 (Base)**: No FK dependencies - can be created first
- **Tier 1-7**: Progressive levels of FK dependencies

---

## Tier 0 - Base Tables (No FK Dependencies) - 37 Tables

These tables have NO foreign key constraints pointing to other tables and can be created first.

| # | Table Name | Columns | P0 Critical | Notes |
|---|------------|---------|-------------|-------|
| 1 | alembic_version | 1 | | Migration tracking |
| 2 | cm_application | 8 | | Application config |
| 3 | cm_application_group | 2 | | Application groups |
| 4 | cm_group | 5 | | User groups |
| 5 | cm_project | 5 | | Project definitions |
| 6 | cm_unit | 7 | | Unit config |
| 7 | cm_unit_compare | 2 | | Unit comparisons |
| 8 | cm_unit_dimensions | 10 | | Unit dimensions |
| 9 | cm_user | 7 | | User config |
| 10 | cm_user_group | 2 | | User-group mapping |
| 11 | color | 1 | | Color definitions |
| 12 | container_type | 7 | | Container types |
| 13 | display_layout | 2 | | Display layouts |
| 14 | display_type | 2 | | Display types |
| 15 | field_map_block | 3 | | Field map blocks |
| 16 | field_map_set | 6 | | Field map sets |
| 17 | field_map_type | 2 | | Field map types |
| 18 | goo_attachment_type | 2 | | Attachment types |
| 19 | goo_process_queue_type | 2 | | Queue types |
| 20 | **goo_type** | 12 | **P0** | **Material types - CRITICAL** |
| 21 | history_type | 3 | | History types |
| 22 | **m_downstream** | 4 | **P0** | **Cached downstream graph - CRITICAL** |
| 23 | m_number | 1 | | M-number sequence |
| 24 | **m_upstream** | 4 | **P0** | **Cached upstream graph - CRITICAL** |
| 25 | m_upstream_dirty_leaves | 1 | | Dirty tracking |
| 26 | manufacturer | 4 | | Manufacturers |
| 27 | migration | 3 | | Migration tracking |
| 28 | person | 8 | | Person records |
| 29 | permissions | 2 | | Permission definitions |
| 30 | prefix_incrementor | 2 | | Prefix sequences |
| 31 | s_number | 1 | | S-number sequence |
| 32 | scraper | 19 | | Scraper config |
| 33 | sequence_type | 2 | | Sequence types |
| 34 | smurf | 6 | | Smurf definitions |
| 35 | tmp_messy_links | 5 | | Temporary cleanup |
| 36 | unit | 6 | | Units of measure |
| 37 | workflow_step_type | 2 | | Workflow step types |

---

## Tier 1 - First Level Dependencies - 10 Tables

These tables have FK constraints ONLY to Tier 0 tables.

| # | Table Name | Dependencies (Parent Tables) | On Delete | Notes |
|---|------------|------------------------------|-----------|-------|
| 1 | coa | goo_type | NO ACTION | Certificate of Analysis |
| 2 | container | container_type | NO ACTION | Container instances |
| 3 | container_type_position | container_type (×2) | NO ACTION | Parent/child positions |
| 4 | external_goo_type | goo_type, manufacturer | NO ACTION | External type mapping |
| 5 | field_map | field_map_block, field_map_type, field_map_set | NO ACTION | Field mapping |
| 6 | goo_type_combine_target | goo_type | NO ACTION | Combine targets |
| 7 | **perseus_user** | manufacturer (×3) | NO ACTION | **P0 - Users, 3 DUPLICATE FKs** |
| 8 | property | unit | NO ACTION | Property definitions |
| 9 | robot_log_type | container_type | NO ACTION | Robot log types |
| 10 | smurf_goo_type | smurf, goo_type | CASCADE | Smurf-goo mapping |

**Note:** perseus_user has 3 duplicate FK constraints to manufacturer.id (FK__perseus_u__manuf__5B3C942F, FK__perseus_u__manuf__5E1900DA, FK__perseus_u__manuf__6001494C)

---

## Tier 2 - Second Level Dependencies - 14 Tables

These tables depend on Tier 0 and Tier 1 tables.

| # | Table Name | Dependencies | On Delete | Notes |
|---|------------|--------------|-----------|-------|
| 1 | coa_spec | coa, property | NO ACTION | COA specifications |
| 2 | feed_type | perseus_user (×2) | NO ACTION | Feed types, unnamed FKs |
| 3 | field_map_display_type | field_map, display_type, display_layout | CASCADE (all 3) | Field display |
| 4 | field_map_display_type_user | perseus_user | CASCADE | User display prefs |
| 5 | goo_type_combine_component | goo_type, goo_type_combine_target | CASCADE | Combine components |
| 6 | history | perseus_user, history_type | NO ACTION | History records |
| 7 | material_inventory_threshold | perseus_user (×2), goo_type | NO ACTION | Inventory thresholds |
| 8 | property_option | property | NO ACTION | Property options |
| 9 | robot_run | container | NO ACTION | Robot runs |
| 10 | saved_search | perseus_user | NO ACTION | Saved searches |
| 11 | smurf_group | perseus_user | NO ACTION | Smurf groups |
| 12 | smurf_property | property, smurf | CASCADE (both) | Smurf properties |
| 13 | submission | perseus_user | NO ACTION | Submissions, unnamed FK |
| 14 | workflow | perseus_user, manufacturer | NO ACTION | Workflow definitions |

---

## Tier 3 - Third Level Dependencies - 8 Tables

These tables have deeper dependency chains.

| # | Table Name | Dependencies | On Delete | Notes |
|---|------------|--------------|-----------|-------|
| 1 | container_history | history, container | CASCADE (both) | Container history |
| 2 | history_value | history | CASCADE | History values |
| 3 | material_inventory_threshold_notify_user | material_inventory_threshold, perseus_user | CASCADE, NO ACTION | Threshold notifications |
| 4 | recipe | perseus_user, feed_type, goo_type, workflow | NO ACTION | Recipes, unnamed FKs |
| 5 | robot_log | robot_log_type, robot_run | NO ACTION | Robot logs, unnamed FK |
| 6 | smurf_group_member | smurf, smurf_group | CASCADE (both) | Group membership |
| 7 | workflow_attachment | perseus_user, workflow | NO ACTION, CASCADE | Workflow attachments |
| 8 | workflow_step | goo_type, property, smurf, workflow, unit | NO ACTION, CASCADE | Workflow steps |

---

## Tier 4 - Fourth Level Dependencies - 6 Tables

| # | Table Name | Dependencies | On Delete | Notes |
|---|------------|--------------|-----------|-------|
| 1 | **fatsmurf** | smurf, container, manufacturer, workflow_step | SET NULL (×2), NO ACTION (×2) | **P0 - Experiments** |
| 2 | recipe_part | goo_type, recipe (×2), unit, workflow_step | NO ACTION | Recipe parts, unnamed FKs |
| 3 | recipe_project_assignment | recipe | NO ACTION | Recipe assignments, unnamed FK |
| 4 | robot_log_container_sequence | sequence_type, container, robot_log | CASCADE (all 3) | Container sequences |
| 5 | robot_log_error | robot_log | CASCADE | Robot errors |
| 6 | workflow_section | workflow, workflow_step | CASCADE, NO ACTION | Workflow sections |

---

## Tier 5 - Fifth Level Dependencies - 5 Tables

| # | Table Name | Dependencies | On Delete | Notes |
|---|------------|--------------|-----------|-------|
| 1 | fatsmurf_attachment | perseus_user, fatsmurf | NO ACTION, CASCADE | Experiment attachments |
| 2 | fatsmurf_comment | perseus_user, fatsmurf | NO ACTION, CASCADE | Experiment comments |
| 3 | fatsmurf_history | history, fatsmurf | CASCADE (both) | Experiment history |
| 4 | fatsmurf_reading | perseus_user, fatsmurf | NO ACTION, CASCADE | Experiment readings |
| 5 | **goo** | goo_type, perseus_user, manufacturer, container, workflow_step, recipe, recipe_part | SET NULL (×2), NO ACTION (×5) | **P0 - Materials** |

---

## Tier 6 - Sixth Level Dependencies - 11 Tables

| # | Table Name | Dependencies | On Delete | Notes |
|---|------------|--------------|-----------|-------|
| 1 | goo_attachment | perseus_user, goo, goo_attachment_type | NO ACTION (×2), CASCADE | Material attachments |
| 2 | goo_comment | perseus_user, goo | NO ACTION, CASCADE | Material comments |
| 3 | goo_history | history, goo | CASCADE (both) | Material history |
| 4 | material_inventory | container (×2), perseus_user (×2), goo, recipe | NO ACTION (all 6) | Inventory, unnamed FKs |
| 5 | material_qc | goo | NO ACTION | QC data, unnamed FK |
| 6 | **material_transition** | **fatsmurf (uid), goo (uid)** | **CASCADE (both), UPDATE CASCADE** | **P0 - Lineage** |
| 7 | poll | fatsmurf_reading, smurf_property | CASCADE, NO ACTION | Poll data |
| 8 | robot_log_read | goo, robot_log, property | NO ACTION, CASCADE (×2) | Robot read logs |
| 9 | robot_log_transfer | goo (×2), robot_log | NO ACTION (×2), CASCADE | Robot transfer logs |
| 10 | submission_entry | smurf, goo, perseus_user, submission | NO ACTION (all 4) | Submission entries, unnamed FKs |
| 11 | **transition_material** | **fatsmurf (uid), goo (uid)** | **CASCADE (both), UPDATE CASCADE** | **P0 - Lineage** |

---

## Tier 7 - Seventh Level Dependencies - 1 Table

| # | Table Name | Dependencies | On Delete | Notes |
|---|------------|--------------|-----------|-------|
| 1 | poll_history | history, poll | CASCADE (both) | Poll history |

---

## Foreign Data Wrapper (FDW) Tables - 8 Tables (Not in Tier Graph)

These tables are accessed via postgres_fdw and have NO FK constraints within Perseus.

### Hermes Schema (6 tables)

| # | Table Name | Columns | Notes |
|---|------------|---------|-------|
| 1 | run | 90 | Fermentation runs (corrected from 8 cols) |
| 2 | run_condition | 4 | Run conditions |
| 3 | run_condition_option | 4 | Condition options |
| 4 | run_condition_value | 5 | Condition values |
| 5 | run_master_condition | 10 | Master conditions |
| 6 | run_master_condition_type | 3 | Condition types |

### Demeter Schema (2 tables)

| # | Table Name | Columns | Notes |
|---|------------|---------|-------|
| 1 | barcodes | 3 | Barcode tracking |
| 2 | seed_vials | 22 | Seed vial inventory (corrected from 11 cols) |

---

## Utility/Special Tables - 1 Table (Not in Tier Graph)

| # | Table Name | Columns | Notes |
|---|------------|---------|-------|
| 1 | perseus_table_and_row_counts | 3 | Utility table for row counts |

---

## P0 Critical Path Tables

These tables form the core material lineage tracking system:

```
                         +------------------+
                         |    goo_type      |  (Tier 0)
                         +--------+---------+
                                  |
                                  v
+------------------+    +------------------+    +------------------+
|   m_upstream     |    |      goo         |    |   m_downstream   |
|   (Tier 0)       |<---|    (Tier 5)      |--->|     (Tier 0)     |
+------------------+    +--------+---------+    +------------------+
                                  |
                    +-------------+-------------+
                    |                           |
                    v                           v
          +------------------+        +------------------+
          |material_transition|        |transition_material|
          |    (Tier 6)       |        |     (Tier 6)      |
          +--------+---------+        +--------+---------+
                    |                           |
                    v                           v
          +------------------+        +------------------+
          |    fatsmurf      |        |    fatsmurf      |
          |   (Tier 4)       |        |    (Tier 4)      |
          +------------------+        +------------------+
```

### Critical Dependencies for `translated` View:

```sql
-- The translated view joins these two tables:
-- material_transition.material_id -> goo.uid (nvarchar)
-- material_transition.transition_id -> fatsmurf.uid (nvarchar)
-- transition_material.transition_id -> fatsmurf.uid (nvarchar)
-- transition_material.material_id -> goo.uid (nvarchar)
```

---

## Circular Dependencies Analysis

**RESULT: NO CIRCULAR DEPENDENCIES DETECTED**

All foreign key relationships form a directed acyclic graph (DAG). The tables can be created in the specified tier order without circular reference issues.

### Potential Cross-Reference (Not Circular):
- `workflow_section.starting_step_id` -> `workflow_step.id`
- `workflow_step.scope_id` -> `workflow.id`
- `workflow_section.workflow_id` -> `workflow.id`

This is NOT circular because:
1. `workflow` is created first (Tier 2)
2. `workflow_step` is created second (Tier 3)
3. `workflow_section` is created last (Tier 4, after workflow_step)

The FK `workflow_section.starting_step_id` is a forward reference that requires `workflow_step` to exist first.

---

## Self-Referential Tables

The following tables have self-referential FKs (parent-child within same table):

| Table | FK Column | Notes |
|-------|-----------|-------|
| recipe_part | part_recipe_id -> recipe.id | Recipe can reference other recipes |
| container_type_position | parent_container_type_id, child_container_type_id | Container hierarchy |

**Impact**: These require careful INSERT order or deferred constraint checking.

---

## Foreign Key Statistics

| Metric | Count |
|--------|-------|
| Total FK Constraints | 124 |
| ON DELETE CASCADE | 40 |
| ON DELETE SET NULL | 4 |
| ON DELETE NO ACTION | 80 |
| ON UPDATE CASCADE | 2 |
| Unnamed FK Constraints | 25 |
| Duplicate FK Constraints | 1 (perseus_user.manufacturer_id ×3) |

---

## Tables with CASCADE DELETE (40 constraints)

The following tables have `ON DELETE CASCADE` behavior that will propagate deletes:

| Parent Table | Child Table | Constraint Name |
|--------------|-------------|-----------------|
| container | robot_log_container_sequence | robot_log_container_sequence_FK_2 |
| display_layout | field_map_display_type | combined_field_map_display_type_FK_3 |
| display_type | field_map_display_type | combined_field_map_display_type_FK_2 |
| **fatsmurf (uid)** | **material_transition** | FK_material_transition_fatsmurf |
| **fatsmurf (uid)** | **transition_material** | FK_transition_material_fatsmurf |
| fatsmurf | fatsmurf_attachment | fatsmurf_attachment_FK_2 |
| fatsmurf | fatsmurf_comment | fatsmurf_comment_FK_2 |
| fatsmurf | fatsmurf_history | fatsmurf_history_FK_2 |
| fatsmurf | fatsmurf_reading | fatsmurf_reading_FK_1 |
| fatsmurf_reading | poll | poll_fatsmurf_reading_FK_1 |
| field_map | field_map_display_type | combined_field_map_display_type_FK_1 |
| **goo (uid)** | **material_transition** | FK_material_transition_goo |
| **goo (uid)** | **transition_material** | FK_transition_material_goo |
| goo | goo_attachment | goo_attachment_FK_2 |
| goo | goo_comment | goo_comment_FK_2 |
| goo | goo_history | goo_history_FK_2 |
| goo_type | smurf_goo_type | smurf_goo_type_FK_2 |
| goo_type_combine_target | goo_type_combine_component | goo_type_combine_component_FK_2 |
| history | container_history | container_history_FK_1 |
| history | fatsmurf_history | fatsmurf_history_FK_1 |
| history | goo_history | goo_history_FK_1 |
| history | history_value | history_value_FK_1 |
| history | poll_history | poll_history_FK_1 |
| material_inventory_threshold | material_inventory_threshold_notify_user | FK_mit_notify_user_threshold |
| perseus_user | field_map_display_type_user | field_map_display_type_user_FK_2 |
| poll | poll_history | poll_history_FK_2 |
| property | robot_log_read | robot_log_read_FK_2 |
| property | smurf_property | smurf_property_FK_1 |
| robot_log | robot_log_container_sequence | robot_log_container_sequence_FK_3 |
| robot_log | robot_log_error | robot_log_error_FK_1 |
| robot_log | robot_log_read | robot_log_read_FK_1 |
| robot_log | robot_log_transfer | robot_log_transfer_FK_1 |
| sequence_type | robot_log_container_sequence | robot_log_container_sequence_FK_1 |
| smurf | smurf_group_member | smurf_group_member_FK_1 |
| smurf | smurf_property | smurf_property_FK_2 |
| smurf_group | smurf_group_member | smurf_group_member_FK_2 |
| workflow | workflow_attachment | workflow_attachment_FK_2 |
| workflow | workflow_section | workflow_section_FK_1 |
| workflow | workflow_step | FK_workflow_step_workflow |

**CRITICAL NOTE**: Deleting a `goo` or `fatsmurf` record will CASCADE to `material_transition` and `transition_material`, affecting the material lineage graph.

---

## Tables with SET NULL on DELETE (4 constraints)

| Parent Table | Child Table | Column |
|--------------|-------------|--------|
| container | fatsmurf | container_id |
| container | goo | container_id |
| workflow_step | fatsmurf | workflow_step_id |
| workflow_step | goo | workflow_step_id |

---

## Tables with UPDATE CASCADE (2 constraints)

| Parent Table | Child Table | FK Constraint |
|--------------|-------------|---------------|
| **goo (uid)** | **material_transition** | FK_material_transition_goo |
| **goo (uid)** | **transition_material** | FK_transition_material_goo |

**Note**: These are the ONLY two constraints with ON UPDATE CASCADE in the entire database.

---

## Special FK Reference Types

### UID-Based Foreign Keys (Non-Integer)

| Child Table | FK Column | Referenced Table | Referenced Column | Data Type |
|-------------|-----------|------------------|-------------------|-----------|
| material_transition | material_id | goo | uid | nvarchar(50) |
| material_transition | transition_id | fatsmurf | uid | nvarchar(50) |
| transition_material | material_id | goo | uid | nvarchar(50) |
| transition_material | transition_id | fatsmurf | uid | nvarchar(50) |

**PostgreSQL Migration Note**: These use `nvarchar(50)` as FK columns referencing `uid` columns, not integer IDs. Ensure proper indexing on `goo.uid` and `fatsmurf.uid` columns.

---

## Unnamed Foreign Key Constraints (25 total)

These FK constraints have NULL fk_name in the metadata:

| Table | Column | Parent Table | Count |
|-------|--------|--------------|-------|
| feed_type | added_by | perseus_user | 1 |
| feed_type | updated_by_id | perseus_user | 1 |
| material_inventory | allocation_container_id | container | 1 |
| material_inventory | created_by_id | perseus_user | 1 |
| material_inventory | location_container_id | container | 1 |
| material_inventory | material_id | goo | 1 |
| material_inventory | recipe_id | recipe | 1 |
| material_inventory | updated_by_id | perseus_user | 1 |
| material_qc | material_id | goo | 1 |
| recipe | added_by | perseus_user | 1 |
| recipe | feed_type_id | feed_type | 1 |
| recipe | goo_type_id | goo_type | 1 |
| recipe | workflow_id | workflow | 1 |
| recipe_part | goo_type_id | goo_type | 1 |
| recipe_part | part_recipe_id | recipe | 1 |
| recipe_part | recipe_id | recipe | 1 |
| recipe_part | unit_id | unit | 1 |
| recipe_part | workflow_step_id | workflow_step | 1 |
| recipe_project_assignment | recipe_id | recipe | 1 |
| robot_log | robot_log_type_id | robot_log_type | 1 |
| submission | submitter_id | perseus_user | 1 |
| submission_entry | assay_type_id | smurf | 1 |
| submission_entry | material_id | goo | 1 |
| submission_entry | prepped_by_id | perseus_user | 1 |
| submission_entry | submission_id | submission | 1 |

**Impact**: These unnamed constraints will receive PostgreSQL auto-generated names (e.g., `table_name_fkey`).

---

## Duplicate Foreign Key Constraints (1 issue)

| Table | Column | Parent Table | Constraint Names |
|-------|--------|--------------|------------------|
| perseus_user | manufacturer_id | manufacturer | FK__perseus_u__manuf__5B3C942F, FK__perseus_u__manuf__5E1900DA, FK__perseus_u__manuf__6001494C |

**Impact**: This is likely a SQL Server migration artifact. PostgreSQL will reject duplicate FK definitions. Only ONE FK constraint should be created.

---

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 2.0 (Corrected) |
| Created | 2026-02-10 |
| DBO Tables | 92 (91 main + 1 utility) |
| FDW Tables | 8 (6 hermes + 2 demeter) |
| Total Tables | 101 |
| FK Constraints | 124 |
| Circular Dependencies | 0 (NONE) |
| Blocking Issues | 0 (NONE) |
| Tiers | 8 (0-7) |
