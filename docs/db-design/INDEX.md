# Perseus Database Design Documentation Index

**Project:** Perseus Database Migration (SQL Server → PostgreSQL 17+)  
**Last Updated:** 2026-02-11  
**Status:** - Table Structures

## Quick Navigation

### Original SQL Server Schema
- **ER Diagram:** [`perseus-ER-Diagram.mmd`](./perseus-ER-Diagram.mmd) (23KB, Mermaid format)
- **Visual Diagram:** [`perseus-ER-Diagram.png`](./perseus-ER-Diagram.png) (3.1MB, PNG)
- **GraphML Export:** [`perseus-ER-dbo.graphml`](./perseus-ER-dbo.graphml) (339KB, yEd format)

### PostgreSQL Transformed Schema
- **Directory:** [`pgsql/`](./pgsql/)
- **ER Diagram:** [`pgsql/perseus-ER-diagram-pgsql.mmd`](./pgsql/perseus-ER-diagram-pgsql.mmd) (24KB)
- **Data Dictionary:** [`pgsql/perseus-data-dictionary.md`](./pgsql/perseus-data-dictionary.md) (43KB)
- **Validation Report:** [`pgsql/validation-report.md`](./pgsql/validation-report.md) (4.4KB)
- **Type Reference:** [`pgsql/TYPE-TRANSFORMATION-REFERENCE.md`](./pgsql/TYPE-TRANSFORMATION-REFERENCE.md) (5.8KB)
- **Directory README:** [`pgsql/README.md`](./pgsql/README.md) (6.2KB)

### Transformation Documentation
- **Transformation Summary:** [`TRANSFORMATION-SUMMARY.md`](./TRANSFORMATION-SUMMARY.md) (9.5KB)

## Schema Statistics

| Metric | SQL Server | PostgreSQL | Match |
|--------|-----------|------------|-------|
| **Tables** | 90 | 90 | ✅ 100% |
| **Relationships** | 120 | 120 | ✅ 100% |
| **Data Types** | SQL Server | PostgreSQL | ✅ 100% transformed |
| **P0 Critical Tables** | 7 | 7 | ✅ Special handling applied |

## Key Transformations

### Type Mapping Summary

| Category | Examples | Count |
|----------|----------|-------|
| **Integer** | `int` → `INTEGER`, `bit` → `INTEGER` | ~400+ |
| **String** | `nvarchar` → `VARCHAR`, `char` → `CHAR` | ~350+ |
| **Date/Time** | `datetime` → `TIMESTAMP` | ~75+ |
| **Numeric** | `float` → `DOUBLE PRECISION` | ~40+ |
| **Binary** | `image` → `BYTEA` | ~10+ |

### P0 Critical Tables (Special Handling)

1. **goo** - UID with UK constraint
2. **fatsmurf** - UID with UK constraint
3. **container** - UID with UK constraint
4. **material_transition** - Composite PK (material_id, transition_id)
5. **transition_material** - Composite PK (transition_id, material_id)
6. **m_upstream** - Composite PK (end_point, start_point, path)
7. **m_downstream** - Composite PK (end_point, start_point, path)

## Documentation Purpose

### For DBAs/Database Engineers
- Use PostgreSQL ER diagram as schema validation reference
- Cross-reference with DDL scripts in `/source/building/pgsql/refactored/`
- Validate index and constraint scripts against relationships

### For Developers
- Understand table relationships and dependencies
- Reference type transformations for application code updates
- Validate ORM mappings against PostgreSQL types

### For QA/Testing
- Generate test data based on schema structure
- Validate data migration type compatibility
- Test referential integrity with relationship mappings

## How to Use This Documentation

### 1. Viewing ER Diagrams

**Mermaid Diagrams (.mmd files):**
- View on GitHub (native rendering)
- Use [Mermaid Live Editor](https://mermaid.live)
- VS Code with "Markdown Preview Mermaid Support" extension

### 2. Validating Table Structures

```bash
# Find a specific table in PostgreSQL diagram
cd pgsql/
sed -n '/^    table_name {$/,/^    }$/p' perseus-ER-diagram-pgsql.mmd

# Example: Find goo table
sed -n '/^    goo {$/,/^    }$/p' perseus-ER-diagram-pgsql.mmd

# List all relationships for a table
grep "table_name" perseus-ER-diagram-pgsql.mmd | grep "}o--||"
```

### 3. Type Transformation Lookup

Refer to [`pgsql/TYPE-TRANSFORMATION-REFERENCE.md`](./pgsql/TYPE-TRANSFORMATION-REFERENCE.md) for:
- Standard type mappings
- Special case handling
- Perseus-specific decisions
- Validation checklist

### 4. Validation Commands

```bash
# Verify transformation completeness
cd pgsql/

# Check for SQL Server types (should be 0)
grep -E "(nvarchar|datetime|datetime2|smalldatetime|uniqueidentifier)" \
  perseus-ER-diagram-pgsql.mmd | wc -l

# Verify table count (should be 90)
grep -c "^    [a-z_]* {$" perseus-ER-diagram-pgsql.mmd

# Verify relationship count (should be 120)
grep -c "}o--||" perseus-ER-diagram-pgsql.mmd
```

## Integration with Project Structure

### DDL Scripts
**Location:** `/source/building/pgsql/refactored/14. create-table/`

**Validation:**
1. Each CREATE TABLE script must match types in PostgreSQL ER diagram
2. Add explicit sizes (VARCHAR(50), NUMERIC(18,6), etc.)
3. Add NOT NULL, DEFAULT, CHECK constraints
4. Use `GENERATED ALWAYS AS IDENTITY` for identity columns

### Index Scripts
**Location:** `/source/building/pgsql/refactored/16. create-index/`

**Validation:**
1. Verify indexed columns exist in ER diagram
2. Match FK relationships for FK indexes
3. Validate PK/UK constraints

### Constraint Scripts
**Location:** `/source/building/pgsql/refactored/17-18. constraints/`

**Validation:**
1. All 120 FK relationships must have constraint scripts
2. PK and UK annotations must match actual constraints
3. Verify referential integrity rules (CASCADE, RESTRICT, etc.)

## Quality Assurance

### Validation Status

| Check | Result | Evidence |
|-------|--------|----------|
| Type transformations | ✅ 100% | [`validation-report.md`](./pgsql/validation-report.md) |
| Structural integrity | ✅ Perfect | 90 tables, 120 relationships preserved |
| P0 critical handling | ✅ Complete | 7 tables with special handling |
| Documentation | ✅ Complete | 4 comprehensive documents |

### Next Validation Steps

1. Cross-reference DDL scripts with PostgreSQL ER diagram
2. Validate index scripts against column existence
3. Verify constraint scripts match relationships
4. Run automated schema validation tests

## Version History

| Version | Date | Description | Author |
|---------|------|-------------|--------|
| 1.0 | 2026-02-11 | Initial ER diagram transformation | Claude Code |
| 1.0 | 2026-02-11 | Validation and documentation | Claude Code |

## References

### Project Documentation
- **Constitution:** `/docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md`
- **Progress Tracker:** `/tracking/progress-tracker.md`

### External Resources
- [PostgreSQL 17 Data Types](https://www.postgresql.org/docs/17/datatype.html)
- [Mermaid ER Diagrams](https://mermaid.js.org/syntax/entityRelationshipDiagram.html)
- [SQL Server Migration Guide](https://wiki.postgresql.org/wiki/Things_to_find_out_about_when_moving_from_Microsoft_SQL_Server_to_PostgreSQL)

---

**Project Lead:** Pierre Ribeiro (Senior DBA/DBRE)  
**Status:** ER Diagram Transformation Complete ✅
