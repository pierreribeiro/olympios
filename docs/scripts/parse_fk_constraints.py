#!/usr/bin/env python3
"""
Parse all FK constraint files and build adjacency list.
Extracts child table, parent table, FK name, columns, and CASCADE actions.
"""

import os
import re
import json
from pathlib import Path
from collections import defaultdict

def parse_fk_file(filepath):
    """Parse a single FK constraint file and extract metadata."""
    with open(filepath, 'r') as f:
        content = f.read()

    # Extract table name from ALTER TABLE
    alter_match = re.search(r'ALTER TABLE\s+\[?(\w+)\]?\.\[?(\w+)\]?', content, re.IGNORECASE)
    if not alter_match:
        return None

    child_schema = alter_match.group(1)
    child_table = alter_match.group(2)

    # Extract FK constraint name (may be unnamed)
    constraint_match = re.search(r'ADD\s+(?:CONSTRAINT\s+\[?(\w+)\]?\s+)?FOREIGN KEY', content, re.IGNORECASE)
    fk_name = constraint_match.group(1) if constraint_match and constraint_match.group(1) else None

    # Extract child columns
    child_cols_match = re.search(r'FOREIGN KEY\s+\(([^)]+)\)', content, re.IGNORECASE)
    if not child_cols_match:
        return None
    child_cols = [col.strip().strip('[]') for col in child_cols_match.group(1).split(',')]

    # Extract parent table and columns
    references_match = re.search(r'REFERENCES\s+\[?(\w+)\]?\.\[?(\w+)\]?\s+\(([^)]+)\)', content, re.IGNORECASE)
    if not references_match:
        return None

    parent_schema = references_match.group(1)
    parent_table = references_match.group(2)
    parent_cols = [col.strip().strip('[]') for col in references_match.group(3).split(',')]

    # Extract CASCADE actions
    on_delete = None
    on_update = None

    delete_match = re.search(r'ON DELETE\s+(CASCADE|SET NULL|SET DEFAULT|NO ACTION|RESTRICT)', content, re.IGNORECASE)
    if delete_match:
        on_delete = delete_match.group(1).upper()

    update_match = re.search(r'ON UPDATE\s+(CASCADE|SET NULL|SET DEFAULT|NO ACTION|RESTRICT)', content, re.IGNORECASE)
    if update_match:
        on_update = update_match.group(1).upper()

    return {
        'child_schema': child_schema,
        'child_table': child_table,
        'parent_schema': parent_schema,
        'parent_table': parent_table,
        'fk_name': fk_name,
        'child_cols': child_cols,
        'parent_cols': parent_cols,
        'on_delete': on_delete,
        'on_update': on_update
    }

def main():
    fk_dir = Path('/Users/pierre.ribeiro/.claude-worktrees/US3-table-structures/source/original/sqlserver/13. create-foreign-key-constraint')

    # Build adjacency list
    adjacency_list = defaultdict(list)
    all_tables = set()
    cross_schema_fks = []
    self_referencing_fks = []

    # Process all FK files
    sql_files = sorted(fk_dir.glob('*.sql'))

    for filepath in sql_files:
        fk_info = parse_fk_file(filepath)
        if not fk_info:
            print(f"Warning: Could not parse {filepath.name}")
            continue

        child_full = f"{fk_info['child_schema']}.{fk_info['child_table']}"
        parent_full = f"{fk_info['parent_schema']}.{fk_info['parent_table']}"

        # Add to adjacency list
        adjacency_list[child_full].append({
            'parent_table': parent_full,
            'fk_name': fk_info['fk_name'],
            'child_cols': fk_info['child_cols'],
            'parent_cols': fk_info['parent_cols'],
            'on_delete': fk_info['on_delete'],
            'on_update': fk_info['on_update']
        })

        # Track all tables
        all_tables.add(child_full)
        all_tables.add(parent_full)

        # Track cross-schema FKs
        if fk_info['child_schema'] != fk_info['parent_schema']:
            cross_schema_fks.append({
                'child': child_full,
                'parent': parent_full,
                'fk_name': fk_info['fk_name']
            })

        # Track self-referencing FKs
        if fk_info['child_table'] == fk_info['parent_table']:
            self_referencing_fks.append({
                'table': child_full,
                'fk_name': fk_info['fk_name'],
                'child_cols': fk_info['child_cols'],
                'parent_cols': fk_info['parent_cols']
            })

    # Convert defaultdict to regular dict for JSON serialization
    adjacency_list_dict = dict(adjacency_list)

    # Build summary
    summary = {
        'total_fk_count': sum(len(fks) for fks in adjacency_list.values()),
        'total_child_tables': len(adjacency_list),
        'total_unique_tables': len(all_tables),
        'all_tables': sorted(all_tables),
        'cross_schema_fks': cross_schema_fks,
        'cross_schema_count': len(cross_schema_fks),
        'self_referencing_fks': self_referencing_fks,
        'self_referencing_count': len(self_referencing_fks)
    }

    # Write adjacency list to JSON
    output_file = Path('/Users/pierre.ribeiro/.claude-worktrees/US3-table-structures/fk_adjacency_list.json')
    with open(output_file, 'w') as f:
        json.dump(adjacency_list_dict, f, indent=2)

    # Write summary to JSON
    summary_file = Path('/Users/pierre.ribeiro/.claude-worktrees/US3-table-structures/fk_summary.json')
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)

    print(f"✓ Parsed {len(sql_files)} FK constraint files")
    print(f"✓ Total FK constraints: {summary['total_fk_count']}")
    print(f"✓ Total child tables with FKs: {summary['total_child_tables']}")
    print(f"✓ Total unique tables (child + parent): {summary['total_unique_tables']}")
    print(f"✓ Cross-schema FKs: {summary['cross_schema_count']}")
    print(f"✓ Self-referencing FKs: {summary['self_referencing_count']}")
    print(f"\nOutput files:")
    print(f"  - {output_file}")
    print(f"  - {summary_file}")

if __name__ == '__main__':
    main()
