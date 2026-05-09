#!/usr/bin/env python3
"""
Generate FK dependency tree showing parent-child relationships.
Identifies root tables, leaf tables, and dependency levels.
"""

import json
from pathlib import Path
from collections import defaultdict, deque

def load_adjacency_list():
    """Load FK adjacency list from JSON."""
    filepath = Path('/Users/pierre.ribeiro/.claude-worktrees/US3-table-structures/fk_adjacency_list.json')
    with open(filepath, 'r') as f:
        return json.load(f)

def build_reverse_index(adjacency_list):
    """Build reverse index: parent → [children]."""
    reverse = defaultdict(list)
    for child, fk_list in adjacency_list.items():
        for fk in fk_list:
            parent = fk['parent_table']
            reverse[parent].append({
                'child_table': child,
                'fk_name': fk['fk_name'],
                'child_cols': fk['child_cols'],
                'parent_cols': fk['parent_cols'],
                'on_delete': fk['on_delete'],
                'on_update': fk['on_update']
            })
    return dict(reverse)

def find_root_tables(adjacency_list, all_tables):
    """Find tables with no FK dependencies (root tables)."""
    child_tables = set(adjacency_list.keys())
    return sorted(all_tables - child_tables)

def find_leaf_tables(reverse_index, all_tables):
    """Find tables that are never referenced (leaf tables)."""
    parent_tables = set(reverse_index.keys())
    return sorted(all_tables - parent_tables)

def calculate_dependency_levels(adjacency_list, root_tables):
    """Calculate dependency level for each table using BFS."""
    levels = {}
    queue = deque()

    # Initialize with root tables at level 0
    for root in root_tables:
        levels[root] = 0
        queue.append(root)

    visited = set(root_tables)

    while queue:
        current = queue.popleft()
        current_level = levels[current]

        # Check if current table is a child of any table
        if current in adjacency_list:
            for fk in adjacency_list[current]:
                parent = fk['parent_table']

                # Calculate new level (max of parent's level + 1)
                new_level = max(levels.get(parent, 0) + 1, current_level)

                if current in levels:
                    levels[current] = max(levels[current], new_level)
                else:
                    levels[current] = new_level

    # Second pass: propagate levels correctly
    changed = True
    max_iterations = 100
    iteration = 0

    while changed and iteration < max_iterations:
        changed = False
        iteration += 1

        for child, fk_list in adjacency_list.items():
            max_parent_level = -1
            for fk in fk_list:
                parent = fk['parent_table']
                if parent in levels:
                    max_parent_level = max(max_parent_level, levels[parent])

            new_level = max_parent_level + 1
            if child not in levels or levels[child] < new_level:
                levels[child] = new_level
                changed = True

    return levels

def count_fk_references(reverse_index):
    """Count how many tables reference each parent."""
    return {parent: len(children) for parent, children in reverse_index.items()}

def main():
    # Load data
    adjacency_list = load_adjacency_list()

    # Build reverse index
    reverse_index = build_reverse_index(adjacency_list)

    # Get all unique tables
    all_tables = set(adjacency_list.keys())
    for fk_list in adjacency_list.values():
        for fk in fk_list:
            all_tables.add(fk['parent_table'])

    # Find root and leaf tables
    root_tables = find_root_tables(adjacency_list, all_tables)
    leaf_tables = find_leaf_tables(reverse_index, all_tables)

    # Calculate dependency levels
    levels = calculate_dependency_levels(adjacency_list, root_tables)

    # Count references
    reference_counts = count_fk_references(reverse_index)

    # Group tables by level
    tables_by_level = defaultdict(list)
    for table, level in levels.items():
        tables_by_level[level].append(table)

    # Sort tables within each level by reference count (descending)
    for level in tables_by_level:
        tables_by_level[level].sort(key=lambda t: reference_counts.get(t, 0), reverse=True)

    # Generate report
    output = []
    output.append("# FK Dependency Tree Analysis")
    output.append("")
    output.append("## Root Tables (Level 0 - No FK Dependencies)")
    output.append(f"**Count:** {len(root_tables)}")
    output.append("")

    for table in root_tables:
        ref_count = reference_counts.get(table, 0)
        children = reverse_index.get(table, [])
        output.append(f"- **{table}** ({ref_count} FK references)")
        if children:
            output.append(f"  - Children: {', '.join(sorted(set(c['child_table'] for c in children)))}")
    output.append("")

    # Dependency levels
    max_level = max(levels.values()) if levels else 0
    output.append(f"## Dependency Levels (0 to {max_level})")
    output.append("")

    for level in range(1, max_level + 1):
        tables = tables_by_level[level]
        output.append(f"### Level {level} ({len(tables)} tables)")
        output.append("")

        for table in tables:
            ref_count = reference_counts.get(table, 0)
            parents = []
            if table in adjacency_list:
                parents = sorted(set(fk['parent_table'] for fk in adjacency_list[table]))

            output.append(f"- **{table}** ({ref_count} FK references)")
            output.append(f"  - Parents: {', '.join(parents)}")

            # Show CASCADE info
            cascades = []
            if table in adjacency_list:
                for fk in adjacency_list[table]:
                    if fk['on_delete'] or fk['on_update']:
                        action = []
                        if fk['on_delete']:
                            action.append(f"DELETE {fk['on_delete']}")
                        if fk['on_update']:
                            action.append(f"UPDATE {fk['on_update']}")
                        cascades.append(f"{fk['parent_table']} ({', '.join(action)})")

            if cascades:
                output.append(f"  - Cascades: {', '.join(cascades)}")
            output.append("")

    # Leaf tables
    output.append("## Leaf Tables (Never Referenced)")
    output.append(f"**Count:** {len(leaf_tables)}")
    output.append("")

    for table in leaf_tables:
        parents = []
        if table in adjacency_list:
            parents = sorted(set(fk['parent_table'] for fk in adjacency_list[table]))
        output.append(f"- **{table}**")
        if parents:
            output.append(f"  - Parents: {', '.join(parents)}")
    output.append("")

    # Top referenced tables
    output.append("## Top 15 Most Referenced Tables (Hub Tables)")
    output.append("")
    sorted_refs = sorted(reference_counts.items(), key=lambda x: x[1], reverse=True)[:15]

    for i, (table, count) in enumerate(sorted_refs, 1):
        level = levels.get(table, 'N/A')
        output.append(f"{i}. **{table}** - {count} FK references (Level {level})")

    # Write to file
    output_file = Path('/Users/pierre.ribeiro/.claude-worktrees/US3-table-structures/FK_DEPENDENCY_TREE.md')
    with open(output_file, 'w') as f:
        f.write('\n'.join(output))

    print(f"✓ Generated FK dependency tree: {output_file}")
    print(f"✓ Root tables (Level 0): {len(root_tables)}")
    print(f"✓ Dependency levels: 0 to {max_level}")
    print(f"✓ Leaf tables: {len(leaf_tables)}")
    print(f"✓ Total tables: {len(all_tables)}")

if __name__ == '__main__':
    main()
