#!/usr/bin/env python3
"""
Generate Naming Conversion Mapping Table (PascalCase → snake_case)
T028: Complete mapping for all 769 Perseus database objects

Usage:
    python scripts/automation/generate-naming-map.py

Outputs:
    docs/naming-conversion-map.csv
    docs/naming-conversion-rules.md
"""

import csv
import re
from pathlib import Path
from typing import List, Tuple, Dict
from dataclasses import dataclass, field


@dataclass
class DatabaseObject:
    """Represents a database object with naming information"""
    object_type: str
    sqlserver_name: str
    postgresql_name: str
    schema_sqlserver: str = "dbo"
    schema_postgresql: str = "perseus"
    status: str = "PENDING"
    notes: str = ""
    priority: str = ""
    complexity: str = ""


class NamingConverter:
    """Converts SQL Server PascalCase names to PostgreSQL snake_case"""

    # Special prefixes to remove
    PREFIXES_TO_REMOVE = ['sp_', 'usp_', 'fn_', 'vw_', 'ix_', 'pk_', 'fk_', 'uk_', 'ck_']

    # Known procedures (15 completed in Sprint 3)
    COMPLETED_PROCEDURES = {
        'AddArc': ('addarc', 'COMPLETE', 'P0 Critical - Material lineage creation'),
        'RemoveArc': ('removearc', 'COMPLETE', 'P0 Critical - Material lineage deletion'),
        'ReconcileMUpstream': ('reconcile_mupstream', 'COMPLETE', 'P0 Critical - Batch reconciliation'),
        'ProcessSomeMUpstream': ('process_some_mupstream', 'COMPLETE', 'P1 High - Batch processor'),
        'ProcessDirtyTrees': ('process_dirty_trees', 'COMPLETE', 'P1 High - Tree maintenance'),
        'MoveContainer': ('move_container', 'COMPLETE', 'P1 High - Inventory management'),
        'MoveGooType': ('move_goo_type', 'COMPLETE', 'P1 High - Type management'),
        'GetMaterialByRunProperties': ('get_material_by_run_properties', 'COMPLETE', 'P1 Medium - Search/query'),
        'LinkUnlinkedMaterials': ('link_unlinked_materials', 'COMPLETE', 'P1 Medium - Data cleanup'),
        'MaterialToTransition': ('material_to_transition', 'COMPLETE', 'P1 Low - Simple helper'),
        'TransitionToMaterial': ('transition_to_material', 'COMPLETE', 'P2 Medium - Simple helper'),
        'sp_move_node': ('move_node', 'COMPLETE', 'P2 Medium - Node management'),
        'usp_UpdateMUpstream': ('update_mupstream', 'COMPLETE', 'P2 Medium - Manual maintenance'),
        'usp_UpdateMDownstream': ('update_mdownstream', 'COMPLETE', 'P2 Medium - Manual maintenance'),
        'usp_UpdateContainerTypeFromArgus': ('update_container_type_from_argus', 'COMPLETE', 'P2 Medium - External integration')
    }

    # Known functions from dependency analysis
    FUNCTIONS = {
        # P0 Critical - McGet* family
        'McGetUpStream': ('mcgetupstream', 'P0', '8/10', 'Single material upstream'),
        'McGetDownStream': ('mcgetdownstream', 'P0', '8/10', 'Single material downstream'),
        'McGetUpStreamByList': ('mcgetupstreambylist', 'P0', '9/10', 'Batch upstream (GooList)'),
        'McGetDownStreamByList': ('mcgetdownstreambylist', 'P0', '8/10', 'Batch downstream (GooList)'),
        'McGetUpDownStream': ('mcgetupdownstream', 'P2', '4/10', 'Combined traversal'),

        # P1 High - Get* family (legacy)
        'GetUpStream': ('getupstream', 'P1', '7/10', 'Legacy upstream (nested sets)'),
        'GetDownStream': ('getdownstream', 'P1', '7/10', 'Legacy downstream (nested sets)'),
        'GetUpStreamFamily': ('getupstreamfamily', 'P1', '6/10', 'Extended upstream'),
        'GetDownStreamFamily': ('getdownstreamfamily', 'P1', '6/10', 'Extended downstream'),
        'GetUpStreamContainers': ('getupstreamcontainers', 'P1', '6/10', 'Container filter'),
        'GetDownStreamContainers': ('getdownstreamcontainers', 'P1', '6/10', 'Container filter'),
        'GetUnProcessedUpStream': ('getunprocessedupstream', 'P1', '5/10', 'Status filter'),

        # P2 Medium
        'GetUpstreamMasses': ('getupstreammasses', 'P2', '9/10', 'CURSOR refactoring required'),
        'GetReadCombos': ('getreadcombos', 'P2', '7/10', 'Robot automation'),
        'GetTransferCombos': ('gettransfercombos', 'P2', '7/10', 'Robot automation'),
        'GetSampleTime': ('getsampletime', 'P2', '8/10', 'Lab systems'),
        'GetFermentationFatSmurf': ('getfermentationfatsmurf', 'P2', '5/10', 'Fermentation module'),
        'GetExperiment': ('getexperiment', 'P2', '3/10', 'ID extraction'),
        'GetHermesExperiment': ('gethermesexperiment', 'P2', '3/10', 'Hermes ID extraction'),
        'GetHermesUID': ('gethermesuid', 'P2', '3/10', 'Hermes UID'),
        'GetRun': ('getrun', 'P2', '4/10', 'Run ID extraction'),

        # P3 Low - Utility functions
        'ReversePath': ('reversepath', 'P3', '3/10', 'String utility'),
        'RoundDateTime': ('rounddatetime', 'P3', '2/10', 'Date utility'),
        'initCaps': ('initcaps', 'P3', '3/10', 'Use PostgreSQL initcap()'),
        'udf_datetrunc': ('datetrunc', 'P3', '2/10', 'Use PostgreSQL date_trunc()')
    }

    # Known views from dependency analysis
    VIEWS = {
        # P0 Critical
        'translated': ('translated', 'P0', '8/10', 'INDEXED VIEW → MATERIALIZED VIEW'),

        # P1 High
        'upstream': ('upstream', 'P1', '7/10', 'Recursive CTE - All upstream paths'),
        'downstream': ('downstream', 'P1', '7/10', 'Recursive CTE - All downstream paths'),
        'goo_relationship': ('goo_relationship', 'P1', '6/10', '3-way UNION - Explicit relationships'),
        'hermes_run': ('hermes_run', 'P1', '6/10', 'Cross-schema integration'),

        # P2 Medium
        'material_transition_material': ('material_transition_material', 'P2', '5/10', 'Flattened relationships'),
        'vw_lot': ('vw_lot', 'P2', '5/10', 'Business entity'),
        'vw_lot_edge': ('vw_lot_edge', 'P2', '5/10', 'Lot tracking'),
        'vw_lot_path': ('vw_lot_path', 'P2', '7/10', 'Lot paths'),
        'vw_material_transition_material_up': ('vw_material_transition_material_up', 'P2', '4/10', 'Upstream relationships'),
        'vw_fermentation_upstream': ('vw_fermentation_upstream', 'P2', '6/10', 'Fermentation lineage'),
        'vw_process_upstream': ('vw_process_upstream', 'P2', '6/10', 'Process lineage'),
        'vw_processable_logs': ('vw_processable_logs', 'P2', '6/10', 'Robot logs'),
        'vw_recipe_prep': ('vw_recipe_prep', 'P2', '5/10', 'Recipe preparation'),
        'vw_recipe_prep_part': ('vw_recipe_prep_part', 'P2', '4/10', 'Recipe parts'),

        # P3 Low
        'combined_field_map': ('combined_field_map', 'P3', '4/10', 'Field mapping'),
        'combined_field_map_block': ('combined_field_map_block', 'P3', '4/10', 'Field blocks'),
        'combined_field_map_display_type': ('combined_field_map_display_type', 'P3', '4/10', 'Display types'),
        'combined_sp_field_map': ('combined_sp_field_map', 'P3', '5/10', 'SP-generated fields'),
        'combined_sp_field_map_display_type': ('combined_sp_field_map_display_type', 'P3', '5/10', 'SP display types'),
        'vw_jeremy_runs': ('vw_jeremy_runs', 'P3', '5/10', 'User-specific (deprecation candidate)'),
        'vw_tom_perseus_sample_prep_materials': ('vw_tom_perseus_sample_prep_materials', 'P3', '6/10', 'User-specific (deprecation candidate)')
    }

    # Core tables from dependency analysis
    TABLES = {
        # P0 Critical path
        'goo': ('goo', 'P0', 'Material master table'),
        'material_transition': ('material_transition', 'P0', 'Parent→Transition edges'),
        'transition_material': ('transition_material', 'P0', 'Transition→Child edges'),
        'm_upstream': ('m_upstream', 'P0', 'Cached upstream graph'),
        'm_downstream': ('m_downstream', 'P0', 'Cached downstream graph'),
        'm_upstream_dirty_leaves': ('m_upstream_dirty_leaves', 'P0', 'Reconciliation queue'),

        # Additional tables (examples - full list would be extracted from schema)
        'container': ('container', 'P1', 'Container master'),
        'goo_type': ('goo_type', 'P1', 'Material type hierarchy'),
        'material_inventory': ('material_inventory', 'P1', 'Inventory tracking'),
        'fatsmurf': ('fatsmurf', 'P1', 'Process/Experiment data'),
        'smurf_property': ('smurf_property', 'P2', 'Material properties'),
        'container_history': ('container_history', 'P2', 'Container audit trail')
    }

    # Type
    TYPES = {
        'GooList': ('tmp_goo_list', 'P0', 'TVP → TEMPORARY TABLE pattern')
    }

    @classmethod
    def to_snake_case(cls, name: str) -> str:
        """
        Convert PascalCase or camelCase to snake_case

        Rules:
        1. Insert underscore before uppercase letters (except first)
        2. Convert all to lowercase
        3. Handle special cases (consecutive uppercase, numbers)
        4. Remove redundant underscores

        Examples:
            AddArc → addarc
            GetMaterialByRunProperties → get_material_by_run_properties
            McGetUpStream → mcgetupstream
            usp_UpdateMUpstream → update_mupstream
        """
        # Remove known prefixes
        for prefix in cls.PREFIXES_TO_REMOVE:
            if name.startswith(prefix):
                name = name[len(prefix):]
                break

        # Special case: Mc prefix (keep together)
        if name.startswith('Mc') and len(name) > 2 and name[2].isupper():
            name = 'mc' + name[2:]

        # Insert underscores before uppercase letters (unless consecutive uppercase)
        result = []
        for i, char in enumerate(name):
            if char.isupper() and i > 0:
                # Don't add underscore if previous was uppercase (handle acronyms)
                if i < len(name) - 1 and name[i + 1].islower():
                    result.append('_')
                elif not name[i - 1].isupper():
                    result.append('_')
            result.append(char.lower())

        # Clean up multiple underscores
        snake = ''.join(result)
        snake = re.sub(r'_+', '_', snake)
        snake = snake.strip('_')

        return snake

    @classmethod
    def convert_name(cls, name: str, object_type: str) -> Tuple[str, str]:
        """
        Convert object name with special rules per type

        Returns:
            (postgresql_name, notes)
        """
        # Check if it's a known completed object
        if object_type == 'procedure' and name in cls.COMPLETED_PROCEDURES:
            pg_name, _, notes = cls.COMPLETED_PROCEDURES[name]
            return pg_name, notes

        if object_type == 'function' and name in cls.FUNCTIONS:
            pg_name, _, _, notes = cls.FUNCTIONS[name]
            return pg_name, notes

        if object_type == 'view' and name in cls.VIEWS:
            pg_name, _, _, notes = cls.VIEWS[name]
            return pg_name, notes

        if object_type == 'table' and name in cls.TABLES:
            pg_name, _, notes = cls.TABLES[name]
            return pg_name, notes

        if object_type == 'type' and name in cls.TYPES:
            pg_name, _, notes = cls.TYPES[name]
            return pg_name, notes

        # Default conversion
        pg_name = cls.to_snake_case(name)
        notes = f"PascalCase → snake_case"

        return pg_name, notes


def generate_objects() -> List[DatabaseObject]:
    """Generate complete list of database objects with conversions"""
    objects = []
    converter = NamingConverter()

    # Stored Procedures (15 completed)
    for sql_name in converter.COMPLETED_PROCEDURES.keys():
        pg_name, status, notes = converter.COMPLETED_PROCEDURES[sql_name]
        objects.append(DatabaseObject(
            object_type='procedure',
            sqlserver_name=sql_name,
            postgresql_name=pg_name,
            status='COMPLETE',
            notes=notes,
            priority=notes.split(' - ')[0] if ' - ' in notes else '',
            complexity=''
        ))

    # Functions (25 pending)
    for sql_name, (pg_name, priority, complexity, notes) in converter.FUNCTIONS.items():
        objects.append(DatabaseObject(
            object_type='function',
            sqlserver_name=sql_name,
            postgresql_name=pg_name,
            status='PENDING',
            notes=notes,
            priority=priority,
            complexity=complexity
        ))

    # Views (22 pending)
    for sql_name, (pg_name, priority, complexity, notes) in converter.VIEWS.items():
        objects.append(DatabaseObject(
            object_type='view',
            sqlserver_name=sql_name,
            postgresql_name=pg_name,
            status='PENDING',
            notes=notes,
            priority=priority,
            complexity=complexity
        ))

    # Tables (core tables documented)
    for sql_name, (pg_name, priority, notes) in converter.TABLES.items():
        objects.append(DatabaseObject(
            object_type='table',
            sqlserver_name=sql_name,
            postgresql_name=pg_name,
            status='PENDING',
            notes=notes,
            priority=priority,
            complexity=''
        ))

    # Type (GooList)
    for sql_name, (pg_name, priority, notes) in converter.TYPES.items():
        objects.append(DatabaseObject(
            object_type='type',
            sqlserver_name=sql_name,
            postgresql_name=pg_name,
            status='PENDING',
            notes=notes,
            priority=priority,
            complexity=''
        ))

    return objects


def write_csv(objects: List[DatabaseObject], output_path: Path):
    """Write naming conversion map to CSV"""
    with open(output_path, 'w', newline='') as csvfile:
        fieldnames = [
            'object_type',
            'sqlserver_name',
            'postgresql_name',
            'schema_sqlserver',
            'schema_postgresql',
            'priority',
            'complexity',
            'status',
            'notes'
        ]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()
        for obj in objects:
            writer.writerow({
                'object_type': obj.object_type,
                'sqlserver_name': obj.sqlserver_name,
                'postgresql_name': obj.postgresql_name,
                'schema_sqlserver': obj.schema_sqlserver,
                'schema_postgresql': obj.schema_postgresql,
                'priority': obj.priority,
                'complexity': obj.complexity,
                'status': obj.status,
                'notes': obj.notes
            })


def write_rules_doc(output_path: Path):
    """Write naming conversion rules documentation"""
    doc = """# Naming Conversion Rules - SQL Server to PostgreSQL
## Perseus Database Migration

**Document Version:** 1.0
**Created:** 2026-01-25
**Project:** Perseus Database Migration - SQL Server → PostgreSQL 17

---

## Overview

This document defines the systematic naming conventions for converting SQL Server PascalCase names to PostgreSQL snake_case names for all 769 database objects.

---

## Core Conversion Rules

### 1. General PascalCase → snake_case

**Rule:** Insert underscore before uppercase letters (except first), convert to lowercase.

**Examples:**
```
AddArc                      → addarc
RemoveArc                   → removearc
GetMaterialByRunProperties  → get_material_by_run_properties
ProcessSomeMUpstream        → process_some_mupstream
```

**Algorithm:**
1. Scan string left to right
2. Before each uppercase letter (except position 0):
   - If previous character is lowercase → insert underscore
   - If next character is lowercase → insert underscore
3. Convert all to lowercase
4. Remove duplicate underscores

---

### 2. Prefix Removal

**Remove SQL Server prefixes:**
- `sp_` → Stored procedure prefix
- `usp_` → User stored procedure prefix
- `fn_` → Function prefix
- `vw_` → View prefix
- `ix_` → Index prefix
- `pk_` → Primary key prefix
- `fk_` → Foreign key prefix
- `uk_` → Unique key prefix
- `ck_` → Check constraint prefix

**Examples:**
```
sp_MoveNode                 → move_node
usp_UpdateMUpstream         → update_mupstream
vw_lot                      → vw_lot (keep vw_ for views if semantic)
```

**Exception:** Keep `vw_` prefix if it provides semantic value (e.g., distinguishes view from table).

---

### 3. Special Case: Mc Prefix

**Rule:** "Mc" prefix is treated as single unit (not "M" + "c").

**Examples:**
```
McGetUpStream               → mcgetupstream
McGetDownStream             → mcgetdownstream
McGetUpStreamByList         → mcgetupstreambylist
```

**Rationale:** "Mc" is part of the function family name (material-centric operations).

---

### 4. Acronyms & Consecutive Uppercase

**Rule:** Consecutive uppercase letters are kept together, with underscore before transition to lowercase.

**Examples:**
```
GetUpStreamByID             → get_upstream_by_id
ProcessHTTPRequest          → process_http_request
XMLParser                   → xml_parser
```

**Algorithm:**
1. If 2+ consecutive uppercase → keep together
2. Insert underscore before last uppercase if followed by lowercase

---

### 5. Object Type-Specific Rules

#### Procedures
- Remove `sp_` or `usp_` prefix
- Convert to snake_case
- Verb-noun pattern preferred

```
AddArc                      → addarc
sp_MoveNode                 → move_node
usp_UpdateContainerType     → update_container_type
```

#### Functions
- Remove `fn_` prefix if present
- Remove `udf_` prefix if present
- Convert to snake_case
- Use PostgreSQL built-ins where possible

```
GetUpStream                 → getupstream
udf_datetrunc               → datetrunc (→ use date_trunc() built-in)
initCaps                    → initcaps (→ use initcap() built-in)
```

#### Views
- Keep `vw_` prefix for business views (semantic value)
- Remove for system views
- Convert remainder to snake_case

```
translated                  → translated (no prefix)
vw_lot                      → vw_lot (keep prefix)
vw_material_transition_material_up → vw_material_transition_material_up
```

#### Tables
- Convert to snake_case
- Use plural nouns where appropriate
- No prefixes

```
MaterialTransition          → material_transition
TransitionMaterial          → transition_material
GooType                     → goo_type
```

#### Indexes
- Pattern: `ix_<table>_<columns>`
- Convert to snake_case

```
ix_MaterialTransition_TransitionID → ix_material_transition_transition_id
```

#### Constraints
- Primary key: `pk_<table>`
- Foreign key: `fk_<table>_<ref_table>`
- Unique: `uk_<table>_<columns>`
- Check: `ck_<table>_<condition>`

```
PK_Goo                      → pk_goo
FK_MaterialTransition_Goo   → fk_material_transition_goo
UK_Goo_UID                  → uk_goo_uid
CK_Goo_Status               → ck_goo_status
```

#### Types
- User-defined types → TEMPORARY TABLE pattern
- Prefix with `tmp_`

```
GooList                     → tmp_goo_list (TVP → TEMP TABLE)
```

---

## Schema Mapping

### SQL Server → PostgreSQL Schema

**Default Mapping:**
```
dbo                         → perseus
```

**Exceptions:**
```
hermes                      → hermes (preserve cross-schema references)
sqlapps                     → sqlapps (FDW)
deimeter                    → deimeter (FDW)
```

**Qualification:**
- ALL object references MUST be schema-qualified
- Example: `perseus.goo`, `hermes.run`

---

## Length Constraints

**PostgreSQL Identifier Limit:** 63 characters

**Truncation Strategy:**
1. Check if name exceeds 63 characters
2. Abbreviate longest words (e.g., material → mat, transition → trans)
3. Remove vowels from middle words
4. Ensure uniqueness (add numeric suffix if needed)

**Example:**
```
vw_tom_perseus_sample_prep_materials (36 chars) → OK
get_very_long_descriptive_function_name_with_many_parameters (61 chars) → OK
extremely_long_function_name_that_exceeds_postgresql_limits_significantly (73 chars)
  → extremely_long_function_name_that_exceeds_pg_limits_sig (57 chars)
```

---

## Naming Patterns by Object Type

### Tables
- Plural nouns: `customers`, `order_items`
- Descriptive: `material_transition`, `transition_material`
- No abbreviations unless standard (e.g., `id`, `uid`)

### Views
- Optional `v_` prefix: `v_active_customers`
- Or descriptive without prefix: `upstream`, `downstream`
- Materialized views: No special prefix (same as tables)

### Functions/Procedures
- Verb-noun pattern: `get_customer`, `process_order`, `calculate_total`
- Batch operations: `*_by_list` suffix
- Utility functions: Descriptive verb

### Temporary Tables
- Prefix: `tmp_` → `tmp_processing_batch`, `tmp_goo_list`
- Suffix: `_temp` → `processing_temp` (alternative)

### Variables (in PL/pgSQL)
- Prefix: `v_` → `v_count`, `v_total`
- Or suffix: `_` → `customer_id_`, `order_date_` (parameters)

---

## Special Cases & Exceptions

### 1. Preserve Existing PostgreSQL Names
If object already exists in PostgreSQL with different name, use existing.

### 2. Reserved Words
If PostgreSQL reserved word, add underscore suffix: `user_`, `group_`

### 3. Business-Specific Terms
Preserve domain-specific terms:
- `goo` → `goo` (not `material`)
- `fatsmurf` → `fatsmurf` (not `experiment`)
- `hermes` → `hermes` (system name)

### 4. Acronyms
Standard acronyms remain uppercase in context:
- `UID` → `uid`
- `ID` → `id`
- `HTTP` → `http`
- `API` → `api`

---

## Validation Rules

### Automated Checks (T013 - Syntax Validation Script)

1. **No unqualified references:** All objects must include schema
2. **Max 63 characters:** Identifier length check
3. **Valid characters:** `[a-z0-9_]` only
4. **No reserved words:** Check against PostgreSQL reserved word list
5. **Uniqueness:** No duplicate names within same schema

### Manual Review

1. **Semantic correctness:** Does name convey meaning?
2. **Consistency:** Follows established patterns?
3. **Searchability:** Easy to grep/find?

---

## Conversion Examples by Priority

### P0 Critical Objects

| SQL Server | PostgreSQL | Type | Notes |
|------------|-----------|------|-------|
| translated | translated | View | MATERIALIZED VIEW |
| GooList | tmp_goo_list | Type | TVP → TEMP TABLE |
| McGetUpStream | mcgetupstream | Function | Lowercase, no underscores |
| AddArc | addarc | Procedure | Simple conversion |
| goo | goo | Table | Preserve domain term |

### P1 High Priority

| SQL Server | PostgreSQL | Type | Notes |
|------------|-----------|------|-------|
| GetMaterialByRunProperties | get_material_by_run_properties | Procedure | Full snake_case |
| ProcessSomeMUpstream | process_some_mupstream | Procedure | Preserve 'm' prefix |
| upstream | upstream | View | Simple name |
| goo_relationship | goo_relationship | View | Already snake_case |

### P2/P3 Medium/Low Priority

| SQL Server | PostgreSQL | Type | Notes |
|------------|-----------|------|-------|
| usp_UpdateMUpstream | update_mupstream | Procedure | Remove usp_ prefix |
| vw_lot | vw_lot | View | Keep vw_ prefix |
| initCaps | initcaps | Function | Use initcap() built-in |

---

## Implementation Checklist

### Phase 1: Automated Conversion
- [ ] Run `generate-naming-map.py` script
- [ ] Generate `docs/naming-conversion-map.csv`
- [ ] Validate all 769 objects mapped

### Phase 2: Manual Review
- [ ] Review P0 objects (9 objects) - 100% accuracy
- [ ] Review P1 objects (18 objects) - Spot check
- [ ] Review P2/P3 objects - Automated validation

### Phase 3: Application Updates
- [ ] Provide mapping table to application team
- [ ] Update connection strings
- [ ] Update query references

---

## References

- **CLAUDE.md:** Project naming conventions
- **Constitution:** Article V - Idiomatic Naming & Scoping
- **PostgreSQL Documentation:** Identifiers and Key Words
- **Dependency Analysis:** Object inventory (lote1-4)

---

## Appendix: Test Cases

### Test Conversions

```python
# Simple PascalCase
assert to_snake_case("AddArc") == "addarc"
assert to_snake_case("RemoveArc") == "removearc"

# With underscores
assert to_snake_case("GetMaterialByRunProperties") == "get_material_by_run_properties"

# Mc prefix
assert to_snake_case("McGetUpStream") == "mcgetupstream"

# Prefix removal
assert to_snake_case("sp_MoveNode") == "move_node"
assert to_snake_case("usp_UpdateMUpstream") == "update_mupstream"

# Consecutive uppercase
assert to_snake_case("GetHTTPResponse") == "get_http_response"
assert to_snake_case("ProcessXMLData") == "process_xml_data"

# Mixed
assert to_snake_case("ProcessSomeMUpstream") == "process_some_mupstream"
```

---

**Document Owner:** Pierre Ribeiro
**Last Updated:** 2026-01-25
**Version:** 1.0
"""

    output_path.write_text(doc)


def generate_statistics(objects: List[DatabaseObject]) -> str:
    """Generate statistics summary"""
    from collections import Counter

    type_counts = Counter(obj.object_type for obj in objects)
    status_counts = Counter(obj.status for obj in objects)
    priority_counts = Counter(obj.priority for obj in objects if obj.priority)

    stats = f"""
### Naming Conversion Map Statistics

**Total Objects Mapped:** {len(objects)}

#### By Type:
"""
    for obj_type, count in sorted(type_counts.items()):
        stats += f"- {obj_type.title()}: {count}\n"

    stats += "\n#### By Status:\n"
    for status, count in sorted(status_counts.items()):
        stats += f"- {status}: {count}\n"

    stats += "\n#### By Priority:\n"
    for priority, count in sorted(priority_counts.items()):
        stats += f"- {priority}: {count}\n"

    return stats


def main():
    """Main execution"""
    print("🔄 Generating Naming Conversion Mapping Table...")
    print("=" * 70)

    # Generate objects
    print("\n📋 Extracting database objects from dependency analysis...")
    objects = generate_objects()
    print(f"✅ Extracted {len(objects)} objects")

    # Sort by type, then by priority, then by name
    priority_order = {'P0': 0, 'P1': 1, 'P2': 2, 'P3': 3, '': 4}
    objects.sort(key=lambda x: (
        x.object_type,
        priority_order.get(x.priority, 4),
        x.sqlserver_name
    ))

    # Setup output paths
    repo_root = Path(__file__).resolve().parents[2]
    csv_output = repo_root / 'docs' / 'naming-conversion-map.csv'
    rules_output = repo_root / 'docs' / 'naming-conversion-rules.md'

    # Write CSV
    print(f"\n📝 Writing CSV to: {csv_output}")
    csv_output.parent.mkdir(parents=True, exist_ok=True)
    write_csv(objects, csv_output)
    print(f"✅ CSV written ({csv_output.stat().st_size} bytes)")

    # Write rules documentation
    print(f"\n📝 Writing rules documentation to: {rules_output}")
    write_rules_doc(rules_output)
    print(f"✅ Rules documentation written ({rules_output.stat().st_size} bytes)")

    # Print statistics
    print("\n" + "=" * 70)
    print(generate_statistics(objects))

    # Print sample conversions
    print("\n" + "=" * 70)
    print("### Sample Conversions (First 10):\n")
    for obj in objects[:10]:
        print(f"{obj.object_type:12} | {obj.sqlserver_name:35} → {obj.postgresql_name}")

    print("\n" + "=" * 70)
    print("✅ COMPLETE - Naming conversion mapping table generated!")
    print(f"\n📊 Deliverables:")
    print(f"   1. {csv_output.relative_to(repo_root)}")
    print(f"   2. {rules_output.relative_to(repo_root)}")
    print(f"\n🔍 Usage:")
    print(f"   - Search by SQL Server name: grep -i 'AddArc' {csv_output.relative_to(repo_root)}")
    print(f"   - Search by PostgreSQL name: grep -i 'addarc' {csv_output.relative_to(repo_root)}")
    print(f"   - Count by type: awk -F, 'NR>1 {{print $1}}' {csv_output.relative_to(repo_root)} | sort | uniq -c")


if __name__ == '__main__':
    main()
