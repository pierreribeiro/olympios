#!/usr/bin/env python3
"""
Generate comprehensive PostgreSQL data dictionary for Perseus database migration.
Reads all table DDL files, constraints, and indexes to create complete documentation.
"""

import re
from pathlib import Path
from typing import Dict

# Base paths
BASE_DIR = Path("/Users/pierre.ribeiro/.claude-worktrees/US3-table-structures")
TABLE_DIR = BASE_DIR / "source/building/pgsql/refactored/14. create-table"
CONSTRAINT_DIR = BASE_DIR / "source/building/pgsql/refactored/17. create-constraint"
INDEX_FILE = BASE_DIR / "source/building/pgsql/refactored/16. create-index/00-all-sqlserver-indexes-master.sql"
OUTPUT_FILE = BASE_DIR / "docs/db-design/pgsql/perseus-data-dictionary.md"

# Tier classification from dependency graph
TIERS = {
    0: ['alembic_version', 'cm_application', 'cm_application_group', 'cm_group', 'cm_project',
        'cm_unit', 'cm_unit_compare', 'cm_unit_dimensions', 'cm_user', 'cm_user_group',
        'color', 'container_type', 'display_layout', 'display_type', 'field_map_block',
        'field_map_set', 'field_map_type', 'goo_attachment_type', 'goo_process_queue_type',
        'goo_type', 'history_type', 'm_downstream', 'm_number', 'm_upstream',
        'm_upstream_dirty_leaves', 'manufacturer', 'migration', 'person', 'permissions',
        'prefix_incrementor', 's_number', 'scraper', 'sequence_type', 'smurf',
        'tmp_messy_links', 'unit', 'workflow_step_type'],
    1: ['coa', 'container', 'container_type_position', 'external_goo_type', 'field_map',
        'goo_type_combine_target', 'perseus_user', 'property', 'robot_log_type', 'smurf_goo_type'],
    2: ['coa_spec', 'feed_type', 'field_map_display_type', 'field_map_display_type_user',
        'goo_type_combine_component', 'history', 'material_inventory_threshold',
        'property_option', 'robot_run', 'saved_search', 'smurf_group', 'smurf_property',
        'submission', 'workflow'],
    3: ['container_history', 'history_value', 'material_inventory_threshold_notify_user',
        'recipe', 'robot_log', 'smurf_group_member', 'workflow_attachment', 'workflow_step'],
    4: ['fatsmurf', 'recipe_part', 'recipe_project_assignment', 'robot_log_container_sequence',
        'robot_log_error', 'workflow_section'],
    5: ['fatsmurf_attachment', 'fatsmurf_comment', 'fatsmurf_history', 'fatsmurf_reading', 'goo'],
    6: ['goo_attachment', 'goo_comment', 'goo_history', 'material_inventory', 'material_qc',
        'material_transition', 'poll', 'robot_log_read', 'robot_log_transfer',
        'submission_entry', 'transition_material'],
    7: ['poll_history']
}

# P0 critical tables
P0_CRITICAL = ['goo', 'goo_type', 'fatsmurf', 'container', 'material_transition',
               'transition_material', 'm_upstream', 'm_downstream']

# FDW tables
FDW_HERMES = ['hermes_run', 'hermes_run_condition', 'hermes_run_condition_option',
              'hermes_run_condition_value', 'hermes_run_master_condition',
              'hermes_run_master_condition_type']
FDW_DEMETER = ['demeter_barcodes', 'demeter_seed_vials']
UTILITY_TABLES = ['perseus_table_and_row_counts', 'demeter_fdw_setup', 'hermes_fdw_setup']


def parse_table_ddl(file_path: Path) -> Dict:
    """Parse table DDL file to extract columns and metadata."""
    with open(file_path, 'r') as f:
        content = f.read()

    table_name = file_path.stem
    columns = []

    # Extract columns from CREATE TABLE statement
    in_table = False
    for line in content.split('\n'):
        line = line.strip()

        if 'CREATE TABLE' in line:
            in_table = True
            continue

        if in_table and line.startswith(');'):
            break

        if in_table and line and not line.startswith('--'):
            # Parse column definition
            match = re.match(r'(\w+)\s+(.+?)(?:,\s*)?$', line)
            if match:
                col_name = match.group(1)
                col_def = match.group(2).rstrip(',')
                columns.append((col_name, col_def))

    return {
        'name': table_name,
        'columns': columns,
        'file': file_path
    }


def read_all_tables() -> Dict[str, Dict]:
    """Read all table DDL files."""
    tables = {}

    for sql_file in sorted(TABLE_DIR.glob('*.sql')):
        if sql_file.stem.startswith('.'):
            continue

        table_data = parse_table_ddl(sql_file)
        tables[table_data['name']] = table_data

    return tables


def parse_constraints() -> Dict:
    """Parse constraint files to extract PK, FK, UNIQUE, CHECK constraints."""
    constraints = {
        'pk': {},
        'fk': {},
        'unique': {},
        'check': {}
    }

    # Read primary keys
    pk_file = CONSTRAINT_DIR / "01-primary-key-constraints.sql"
    if pk_file.exists():
        with open(pk_file, 'r') as f:
            content = f.read()

        for match in re.finditer(r'ALTER TABLE perseus\.(\w+)\s+ADD CONSTRAINT (\w+) PRIMARY KEY \(([^)]+)\)', content):
            table_name = match.group(1)
            constraint_name = match.group(2)
            columns = match.group(3)
            constraints['pk'][table_name] = {
                'name': constraint_name,
                'columns': columns
            }

    # Read foreign keys (sample - file is large)
    fk_file = CONSTRAINT_DIR / "02-foreign-key-constraints.sql"
    if fk_file.exists():
        with open(fk_file, 'r') as f:
            content = f.read()

        # Parse FK constraints
        for match in re.finditer(
            r'ALTER TABLE perseus\.(\w+)\s+ADD CONSTRAINT (\w+)\s+FOREIGN KEY \(([^)]+)\)\s+'
            r'REFERENCES perseus\.(\w+) \(([^)]+)\)\s+ON DELETE (\w+(?:\s+\w+)?)\s+ON UPDATE (\w+(?:\s+\w+)?)',
            content
        ):
            child_table = match.group(1)
            constraint_name = match.group(2)
            child_col = match.group(3)
            parent_table = match.group(4)
            parent_col = match.group(5)
            on_delete = match.group(6)
            on_update = match.group(7)

            if child_table not in constraints['fk']:
                constraints['fk'][child_table] = []

            constraints['fk'][child_table].append({
                'name': constraint_name,
                'column': child_col,
                'parent_table': parent_table,
                'parent_column': parent_col,
                'on_delete': on_delete,
                'on_update': on_update
            })

    return constraints


def main():
    """Generate the data dictionary."""
    print("Generating Perseus PostgreSQL Data Dictionary...")
    print(f"Reading tables from: {TABLE_DIR}")

    tables = read_all_tables()
    constraints = parse_constraints()

    print(f"Found {len(tables)} tables")
    print(f"Found {len(constraints['pk'])} primary key constraints")
    print(f"Found {sum(len(v) for v in constraints['fk'].values())} foreign key constraints")

    # Generate basic structure report
    print("\nTable counts by tier:")
    for tier, table_list in sorted(TIERS.items()):
        found = sum(1 for t in table_list if t in tables)
        print(f"  Tier {tier}: {found}/{len(table_list)} tables")

    print(f"\nOutput will be written to: {OUTPUT_FILE}")
    print("\nUse this data to create the full data dictionary markdown file.")


if __name__ == "__main__":
    main()
