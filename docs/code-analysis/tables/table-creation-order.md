# Table Creation Order - Perseus Database Migration

## Overview

This document provides the **flat numbered creation order** for all 92 dbo schema tables based on dependency tier analysis. Tables must be created in this exact order to satisfy foreign key constraints.

**Analysis Date:** 2026-02-10
**Total Tables:** 92 (91 main dbo + 1 utility)
**FDW Tables:** 8 (created separately via CREATE FOREIGN TABLE)
**Dependency Tiers:** 8 (Tier 0-7)

---

## Creation Order Strategy

1. **Tier 0 (Base Tables)**: No FK dependencies - create first (37 tables)
2. **Tier 1-7**: Progressive FK dependencies (55 tables)
3. **FDW Tables**: Created separately after all dbo tables (8 tables)

Within each tier, tables are listed **alphabetically** for consistency.

---

## Table Creation Order (1-92)

### Tier 0: Base Tables (1-37)

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
| 22 | **m_downstream** | 4 | **P0** | **Cached downstream graph** |
| 23 | m_number | 1 | | M-number sequence |
| 24 | **m_upstream** | 4 | **P0** | **Cached upstream graph** |
| 25 | m_upstream_dirty_leaves | 1 | | Dirty tracking |
| 26 | manufacturer | 4 | | Manufacturers |
| 27 | migration | 3 | | Migration tracking |
| 28 | permissions | 2 | | Permission definitions |
| 29 | person | 8 | | Person records |
| 30 | prefix_incrementor | 2 | | Prefix sequences |
| 31 | s_number | 1 | | S-number sequence |
| 32 | scraper | 19 | | Scraper config |
| 33 | sequence_type | 2 | | Sequence types |
| 34 | smurf | 6 | | Smurf definitions |
| 35 | tmp_messy_links | 5 | | Temporary cleanup |
| 36 | unit | 6 | | Units of measure |
| 37 | workflow_step_type | 2 | | Workflow step types |

### Tier 1: First Level Dependencies (38-47)

| # | Table Name | Columns | Dependencies | Notes |
|---|------------|---------|--------------|-------|
| 38 | coa | 3 | goo_type | Certificate of Analysis |
| 39 | container | 13 | container_type | Container instances |
| 40 | container_type_position | 6 | container_type (×2) | Parent/child positions |
| 41 | external_goo_type | 4 | goo_type, manufacturer | External type mapping |
| 42 | field_map | 14 | field_map_block, field_map_type, field_map_set | Field mapping |
| 43 | goo_type_combine_target | 3 | goo_type | Combine targets |
| 44 | **perseus_user** | 9 | manufacturer (×3) | **P0 - Users, 3 duplicate FKs** |
| 45 | property | 4 | unit | Property definitions |
| 46 | robot_log_type | 4 | container_type | Robot log types |
| 47 | smurf_goo_type | 4 | smurf, goo_type | Smurf-goo mapping |

### Tier 2: Second Level Dependencies (48-61)

| # | Table Name | Columns | Dependencies | Notes |
|---|------------|---------|--------------|-------|
| 48 | coa_spec | 9 | coa, property | COA specifications |
| 49 | feed_type | 10 | perseus_user (×2) | Feed types, unnamed FKs |
| 50 | field_map_display_type | 6 | field_map, display_type, display_layout | Field display |
| 51 | field_map_display_type_user | 3 | perseus_user | User display prefs |
| 52 | goo_type_combine_component | 3 | goo_type, goo_type_combine_target | Combine components |
| 53 | history | 4 | perseus_user, history_type | History records |
| 54 | material_inventory_threshold | 12 | perseus_user (×2), goo_type | Inventory thresholds |
| 55 | property_option | 5 | property | Property options |
| 56 | robot_run | 5 | container | Robot runs |
| 57 | saved_search | 8 | perseus_user | Saved searches |
| 58 | smurf_group | 4 | perseus_user | Smurf groups |
| 59 | smurf_property | 6 | property, smurf | Smurf properties |
| 60 | submission | 4 | perseus_user | Submissions, unnamed FK |
| 61 | workflow | 8 | perseus_user, manufacturer | Workflow definitions |

### Tier 3: Third Level Dependencies (62-69)

| # | Table Name | Columns | Dependencies | Notes |
|---|------------|---------|--------------|-------|
| 62 | container_history | 3 | history, container | Container history |
| 63 | history_value | 3 | history | History values |
| 64 | material_inventory_threshold_notify_user | 2 | material_inventory_threshold, perseus_user | Threshold notifications |
| 65 | recipe | 16 | perseus_user, feed_type, goo_type, workflow | Recipes, unnamed FKs |
| 66 | robot_log | 14 | robot_log_type, robot_run | Robot logs, unnamed FK |
| 67 | smurf_group_member | 3 | smurf, smurf_group | Group membership |
| 68 | workflow_attachment | 7 | perseus_user, workflow | Workflow attachments |
| 69 | workflow_step | 17 | goo_type, property, smurf, workflow, unit | Workflow steps |

### Tier 4: Fourth Level Dependencies (70-75)

| # | Table Name | Columns | Dependencies | Notes |
|---|------------|---------|--------------|-------|
| 70 | **fatsmurf** | 18 | smurf, container, manufacturer, workflow_step | **P0 - Experiments** |
| 71 | recipe_part | 11 | goo_type, recipe (×2), unit, workflow_step | Recipe parts, unnamed FKs |
| 72 | recipe_project_assignment | 2 | recipe | Recipe assignments, unnamed FK |
| 73 | robot_log_container_sequence | 5 | sequence_type, container, robot_log | Container sequences |
| 74 | robot_log_error | 3 | robot_log | Robot errors |
| 75 | workflow_section | 4 | workflow, workflow_step | Workflow sections |

### Tier 5: Fifth Level Dependencies (76-80)

| # | Table Name | Columns | Dependencies | Notes |
|---|------------|---------|--------------|-------|
| 76 | fatsmurf_attachment | 8 | perseus_user, fatsmurf | Experiment attachments |
| 77 | fatsmurf_comment | 5 | perseus_user, fatsmurf | Experiment comments |
| 78 | fatsmurf_history | 3 | history, fatsmurf | Experiment history |
| 79 | fatsmurf_reading | 5 | perseus_user, fatsmurf | Experiment readings |
| 80 | **goo** | 20 | goo_type, perseus_user, manufacturer, container, workflow_step, recipe, recipe_part | **P0 - Materials** |

### Tier 6: Sixth Level Dependencies (81-91)

| # | Table Name | Columns | Dependencies | Notes |
|---|------------|---------|--------------|-------|
| 81 | goo_attachment | 9 | perseus_user, goo, goo_attachment_type | Material attachments |
| 82 | goo_comment | 6 | perseus_user, goo | Material comments |
| 83 | goo_history | 3 | history, goo | Material history |
| 84 | material_inventory | 14 | container (×2), perseus_user (×2), goo, recipe | Inventory, unnamed FKs |
| 85 | material_qc | 5 | goo | QC data, unnamed FK |
| 86 | **material_transition** | 3 | **fatsmurf (uid), goo (uid)** | **P0 - Lineage, UID-based FKs** |
| 87 | poll | 11 | fatsmurf_reading, smurf_property | Poll data |
| 88 | robot_log_read | 7 | goo, robot_log, property | Robot read logs |
| 89 | robot_log_transfer | 11 | goo (×2), robot_log | Robot transfer logs |
| 90 | submission_entry | 9 | smurf, goo, perseus_user, submission | Submission entries, unnamed FKs |
| 91 | **transition_material** | 2 | **fatsmurf (uid), goo (uid)** | **P0 - Lineage, UID-based FKs** |

### Tier 7: Seventh Level Dependencies (92)

| # | Table Name | Columns | Dependencies | Notes |
|---|------------|---------|--------------|-------|
| 92 | poll_history | 3 | history, poll | Poll history |

---

## Utility Table (Created Separately)

| Table Name | Columns | Notes |
|------------|---------|-------|
| perseus_table_and_row_counts | 3 | Utility table for row count tracking, no FK dependencies |

---

## FDW Tables (Created Separately via CREATE FOREIGN TABLE)

These tables are NOT part of the dbo schema creation order. They are created via `CREATE FOREIGN TABLE` statements with `postgres_fdw` extension.

### Hermes Schema (6 tables)

| # | Table Name | Columns | Notes |
|---|------------|---------|-------|
| 1 | run | 90 | Fermentation runs |
| 2 | run_condition | 4 | Run conditions |
| 3 | run_condition_option | 4 | Condition options |
| 4 | run_condition_value | 5 | Condition values |
| 5 | run_master_condition | 10 | Master conditions |
| 6 | run_master_condition_type | 3 | Condition types |

### Demeter Schema (2 tables)

| # | Table Name | Columns | Notes |
|---|------------|---------|-------|
| 1 | barcodes | 3 | Barcode tracking |
| 2 | seed_vials | 22 | Seed vial inventory |

---

## Critical Path Tables (P0)

These tables are marked as P0 critical for the material lineage tracking system:

| Creation Order | Table Name | Tier | Notes |
|----------------|------------|------|-------|
| 20 | goo_type | 0 | Material type definitions |
| 22 | m_downstream | 0 | Cached downstream graph |
| 24 | m_upstream | 0 | Cached upstream graph |
| 44 | perseus_user | 1 | User records (3 duplicate FKs) |
| 70 | fatsmurf | 4 | Experiments/transitions |
| 80 | goo | 5 | Materials (core entity) |
| 86 | material_transition | 6 | Material-to-transition lineage |
| 91 | transition_material | 6 | Transition-to-material lineage |

---

## Known Issues

### 1. Duplicate Foreign Keys (1 issue)
- **Table:** perseus_user (creation order #44)
- **Column:** manufacturer_id
- **Issue:** 3 duplicate FK constraints to manufacturer.id
- **Constraint Names:** FK__perseus_u__manuf__5B3C942F, FK__perseus_u__manuf__5E1900DA, FK__perseus_u__manuf__6001494C
- **Resolution:** Create only ONE FK constraint in PostgreSQL

### 2. Unnamed Foreign Keys (25 constraints)
Tables with unnamed FK constraints (will receive PostgreSQL auto-generated names):
- feed_type (2 FKs)
- material_inventory (6 FKs)
- material_qc (1 FK)
- recipe (4 FKs)
- recipe_part (5 FKs)
- recipe_project_assignment (1 FK)
- robot_log (1 FK)
- submission (1 FK)
- submission_entry (4 FKs)

### 3. UID-Based Foreign Keys (4 constraints)
- **Tables:** material_transition, transition_material
- **FK Columns:** material_id (nvarchar), transition_id (nvarchar)
- **Referenced Columns:** goo.uid, fatsmurf.uid
- **Special Behavior:** ON UPDATE CASCADE (only 2 constraints in entire database with this behavior)

---

## Deployment Script Template

```sql
-- Perseus Database - Table Creation Order
-- Execute in this exact order to satisfy FK constraints

-- TIER 0: Base Tables (1-37)
\i 01-alembic_version.sql
\i 02-cm_application.sql
\i 03-cm_application_group.sql
-- ... continue through tier 0

-- TIER 1: First Level Dependencies (38-47)
\i 38-coa.sql
\i 39-container.sql
-- ... continue through tier 1

-- TIER 2-7: Continue in order (48-92)
-- ...

-- FDW Tables (create separately)
\i fdw/hermes_run.sql
\i fdw/hermes_run_condition.sql
-- ... continue FDW tables

-- Utility Table
\i utility/perseus_table_and_row_counts.sql
```

---

## Validation Checklist

After table creation, validate:

- [ ] All 92 dbo tables created successfully
- [ ] All 8 FDW tables created successfully
- [ ] 1 utility table created
- [ ] All 124 FK constraints created (minus 3 duplicates = 121 actual)
- [ ] All PRIMARY KEY constraints created
- [ ] All UNIQUE constraints created
- [ ] All CHECK constraints created
- [ ] No circular dependency errors
- [ ] All indexes created (352 total)

---

## Document Metadata

| Field | Value |
|-------|-------|
| Version | 2.0 (Corrected) |
| Created | 2026-02-10 |
| Total Tables | 101 (92 dbo + 8 FDW + 1 utility) |
| DBO Tables in Order | 92 |
| Dependency Tiers | 8 (0-7) |
| FK Constraints | 124 (121 after duplicate removal) |
| P0 Critical Tables | 8 |
