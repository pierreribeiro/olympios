#!/usr/bin/env python3
"""
Convert SQL Server table DDL to PostgreSQL 17.
Reads from source/original/sqlserver/8. create-table/
Writes to source/building/pgsql/refactored/14. create-table/

Conversion rules:
- Column names: PascalCase → snake_case (only transformation allowed)
- Data types: T-SQL → PostgreSQL mapping
- IDENTITY(1,1) → GENERATED ALWAYS AS IDENTITY
- NVARCHAR → VARCHAR (UTF-8 native)
- DATETIME → TIMESTAMP
- BIT → BOOLEAN
- GETDATE() → CURRENT_TIMESTAMP
- Remove COLLATE clauses
- Remove ON [PRIMARY]
- Schema-qualify to perseus.*
- FDW tables → CREATE FOREIGN TABLE
"""

import os
import re
import json
import sys

SOURCE_DIR = "source/original/sqlserver/8. create-table"
TARGET_DIR = "source/building/pgsql/refactored/14. create-table"
FDW_SCHEMAS = {"hermes", "demeter"}


def to_snake_case(name):
    """Convert PascalCase/camelCase to snake_case. Already-lowercase names pass through."""
    # Remove brackets
    name = name.strip("[]")
    # If already lowercase with underscores, return as-is
    if name == name.lower():
        return name
    # Insert underscore before uppercase letters
    s1 = re.sub(r'([A-Z]+)([A-Z][a-z])', r'\1_\2', name)
    s2 = re.sub(r'([a-z0-9])([A-Z])', r'\1_\2', s1)
    return s2.lower()


def convert_data_type(type_str):
    """Convert SQL Server data type to PostgreSQL."""
    t = type_str.strip().lower()

    # int identity
    if re.match(r'int\s+identity\s*\(\s*\d+\s*,\s*\d+\s*\)', t):
        return "INTEGER GENERATED ALWAYS AS IDENTITY"
    if re.match(r'bigint\s+identity\s*\(\s*\d+\s*,\s*\d+\s*\)', t):
        return "BIGINT GENERATED ALWAYS AS IDENTITY"
    if re.match(r'smallint\s+identity\s*\(\s*\d+\s*,\s*\d+\s*\)', t):
        return "SMALLINT GENERATED ALWAYS AS IDENTITY"

    # nvarchar(max) / varchar(max)
    if re.match(r'n?varchar\s*\(\s*max\s*\)', t):
        return "TEXT"

    # nvarchar(N) → varchar(N)
    m = re.match(r'nvarchar\s*\(\s*(\d+)\s*\)', t)
    if m:
        return f"VARCHAR({m.group(1)})"

    # varchar(N) stays
    m = re.match(r'varchar\s*\(\s*(\d+)\s*\)', t)
    if m:
        return f"VARCHAR({m.group(1)})"

    # float(53) → DOUBLE PRECISION, float(24) → REAL
    m = re.match(r'float\s*\(\s*(\d+)\s*\)', t)
    if m:
        precision = int(m.group(1))
        return "DOUBLE PRECISION" if precision > 24 else "REAL"

    if t == "float":
        return "DOUBLE PRECISION"

    # datetime → TIMESTAMP
    if t == "datetime":
        return "TIMESTAMP"
    if t == "datetime2":
        return "TIMESTAMP"
    if t == "smalldatetime":
        return "TIMESTAMP"

    # date stays
    if t == "date":
        return "DATE"

    # time stays
    if t == "time":
        return "TIME"

    # bit → BOOLEAN
    if t == "bit":
        return "BOOLEAN"

    # int types
    if t == "int":
        return "INTEGER"
    if t == "bigint":
        return "BIGINT"
    if t == "smallint":
        return "SMALLINT"
    if t == "tinyint":
        return "SMALLINT"

    # numeric/decimal
    m = re.match(r'(numeric|decimal)\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)', t)
    if m:
        return f"NUMERIC({m.group(2)},{m.group(3)})"
    m = re.match(r'(numeric|decimal)\s*\(\s*(\d+)\s*\)', t)
    if m:
        return f"NUMERIC({m.group(2)})"

    # money
    if t == "money":
        return "NUMERIC(19,4)"
    if t == "smallmoney":
        return "NUMERIC(10,4)"

    # text/ntext
    if t in ("text", "ntext"):
        return "TEXT"

    # image → BYTEA
    if t == "image":
        return "BYTEA"

    # varbinary
    if re.match(r'varbinary\s*\(\s*max\s*\)', t):
        return "BYTEA"
    m = re.match(r'varbinary\s*\(\s*(\d+)\s*\)', t)
    if m:
        return f"BYTEA"

    # uniqueidentifier → UUID
    if t == "uniqueidentifier":
        return "UUID"

    # xml → XML
    if t == "xml":
        return "XML"

    # char(N)
    m = re.match(r'n?char\s*\(\s*(\d+)\s*\)', t)
    if m:
        return f"CHAR({m.group(1)})"

    # real
    if t == "real":
        return "REAL"

    # Pass through anything else
    return type_str.strip().upper()


def convert_default(default_str):
    """Convert SQL Server DEFAULT to PostgreSQL."""
    if not default_str:
        return None
    d = default_str.strip()

    # Remove outer parens: ((0)) → 0, (getdate()) → getdate()
    while d.startswith("(") and d.endswith(")"):
        inner = d[1:-1]
        # Check balanced parens
        depth = 0
        balanced = True
        for c in inner:
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth < 0:
                    balanced = False
                    break
        if balanced and depth == 0:
            d = inner
        else:
            break

    # getdate() → CURRENT_TIMESTAMP
    if d.lower() in ("getdate()", "sysdatetime()"):
        return "CURRENT_TIMESTAMP"

    # newid() → gen_random_uuid()
    if d.lower() == "newid()":
        return "gen_random_uuid()"

    # Numeric defaults
    if re.match(r'^-?\d+(\.\d+)?$', d):
        return d

    # String defaults
    if d.startswith("'") and d.endswith("'"):
        return d

    # N'string' → 'string'
    if d.startswith("N'") and d.endswith("'"):
        return d[1:]

    return d


def convert_computed_column_expr(expr):
    """Convert SQL Server computed column expression to PostgreSQL."""
    # Remove outer parens
    e = expr.strip()
    while e.startswith("(") and e.endswith(")"):
        e = e[1:-1].strip()

    # Replace getdate() → CURRENT_TIMESTAMP
    e = re.sub(r'getdate\(\)', 'CURRENT_TIMESTAMP', e, flags=re.IGNORECASE)

    # Replace dateadd(unit, amount, date)
    def dateadd_replace(m):
        unit = m.group(1).lower()
        amount = m.group(2).strip()
        date_expr = m.group(3).strip()
        # Convert column refs
        date_expr = re.sub(r'\[(\w+)\]', lambda x: to_snake_case(x.group(1)), date_expr)
        amount = re.sub(r'\[(\w+)\]', lambda x: to_snake_case(x.group(1)), amount)
        unit_map = {"minute": "minutes", "hour": "hours", "day": "days", "month": "months", "year": "years", "second": "seconds"}
        pg_unit = unit_map.get(unit, unit + "s")
        return f"({date_expr} + make_interval({pg_unit} => ({amount})::integer))"

    e = re.sub(r'dateadd\s*\(\s*(\w+)\s*,\s*(.+?)\s*,\s*(.+?)\s*\)', dateadd_replace, e, flags=re.IGNORECASE)

    # Replace column references [col] → col_snake
    e = re.sub(r'\[(\w+)\]', lambda m: to_snake_case(m.group(1)), e)

    # Replace CASE WHEN ... IS NULL THEN ... ELSE ... END
    # Keep as-is (CASE is standard SQL)

    return e


def parse_table_file(filepath):
    """Parse a SQL Server CREATE TABLE file and extract table info."""
    with open(filepath, 'r', encoding='utf-8-sig') as f:
        content = f.read()

    # Extract schema and table name
    m = re.search(r'CREATE\s+TABLE\s+\[(\w+)\]\.\[(\w+)\]\s*\(', content, re.IGNORECASE)
    if not m:
        return None

    schema = m.group(1).lower()
    table_name = m.group(2)

    # Extract everything between the outer parens of CREATE TABLE
    # Find the opening paren after table name
    start = m.end() - 1  # position of opening (

    # Find matching closing paren
    depth = 0
    end = start
    for i in range(start, len(content)):
        if content[i] == '(':
            depth += 1
        elif content[i] == ')':
            depth -= 1
            if depth == 0:
                end = i
                break

    col_block = content[start + 1:end]

    # Parse columns
    columns = []
    # Split on commas that are at the top level (not inside parens)
    parts = []
    current = ""
    depth = 0
    for char in col_block:
        if char == '(':
            depth += 1
        elif char == ')':
            depth -= 1
        elif char == ',' and depth == 0:
            parts.append(current.strip())
            current = ""
            continue
        current += char
    if current.strip():
        parts.append(current.strip())

    for part in parts:
        part = part.strip()
        if not part:
            continue

        # Skip constraint definitions within CREATE TABLE
        if re.match(r'(?:CONSTRAINT|PRIMARY\s+KEY|FOREIGN\s+KEY|UNIQUE|CHECK)\s', part, re.IGNORECASE):
            continue

        # Check for computed column: [name] AS (expression)
        comp_match = re.match(r'\[(\w+)\]\s+AS\s+(.+)', part, re.IGNORECASE | re.DOTALL)
        if comp_match:
            col_name = to_snake_case(comp_match.group(1))
            expr = convert_computed_column_expr(comp_match.group(2))
            columns.append({
                'name': col_name,
                'computed': True,
                'expression': expr
            })
            continue

        # Regular column: [name] type_stuff
        col_match = re.match(r'\[(\w+)\]\s+(.+)', part, re.IGNORECASE | re.DOTALL)
        if not col_match:
            continue

        col_name = to_snake_case(col_match.group(1))
        rest = col_match.group(2).strip()

        # Remove COLLATE clause
        rest = re.sub(r'\s+COLLATE\s+\S+', '', rest, flags=re.IGNORECASE)

        # Extract DEFAULT with proper paren-balanced parsing
        default_val = None
        default_start = -1
        default_end = -1
        dm = re.search(r'\bDEFAULT\s+', rest, re.IGNORECASE)
        if dm:
            default_start = dm.start()
            after_default = rest[dm.end():]
            if after_default.startswith('('):
                # Find matching closing paren
                depth = 0
                for i, c in enumerate(after_default):
                    if c == '(':
                        depth += 1
                    elif c == ')':
                        depth -= 1
                        if depth == 0:
                            default_val = convert_default(after_default[:i + 1])
                            default_end = dm.end() + i + 1
                            break
            else:
                # Non-paren default: take next token
                tok = re.match(r'\S+', after_default)
                if tok:
                    default_val = convert_default(tok.group(0))
                    default_end = dm.end() + tok.end()

        # Extract NULL/NOT NULL
        not_null = bool(re.search(r'\bNOT\s+NULL\b', rest, re.IGNORECASE))
        nullable = bool(re.search(r'(?<!\bNOT\s)\bNULL\b', rest, re.IGNORECASE))

        # Extract data type: remove DEFAULT clause, NULL/NOT NULL from rest
        type_str = rest
        if default_start >= 0 and default_end >= 0:
            type_str = type_str[:default_start] + type_str[default_end:]
        type_str = re.sub(r'\bNOT\s+NULL\b', '', type_str, flags=re.IGNORECASE)
        type_str = re.sub(r'\bNULL\b', '', type_str, flags=re.IGNORECASE)
        type_str = type_str.strip().rstrip(',')

        # Convert data type (including IDENTITY)
        pg_type = convert_data_type(type_str)

        if "GENERATED ALWAYS AS IDENTITY" in pg_type:
            default_val = None
            not_null = True

        columns.append({
            'name': col_name,
            'type': pg_type,
            'not_null': not_null,
            'nullable': nullable and not not_null,
            'default': default_val,
            'computed': False
        })

    return {
        'schema': schema,
        'table': table_name,
        'table_snake': to_snake_case(table_name),
        'columns': columns,
        'is_fdw': schema in FDW_SCHEMAS
    }


def generate_pg_ddl(table_info):
    """Generate PostgreSQL CREATE TABLE DDL."""
    schema = table_info['schema']
    table_snake = table_info['table_snake']
    columns = table_info['columns']
    is_fdw = table_info['is_fdw']

    if is_fdw:
        return generate_fdw_ddl(table_info)

    lines = []
    lines.append(f"-- Table: perseus.{table_snake}")
    lines.append(f"-- Source: SQL Server [{schema}].[{table_info['table']}]")
    lines.append(f"-- Columns: {len(columns)}")
    lines.append("")
    lines.append(f"CREATE TABLE IF NOT EXISTS perseus.{table_snake} (")

    col_lines = []
    for col in columns:
        if col.get('computed'):
            expr = col['expression']
            # Check if expression uses volatile functions (CURRENT_TIMESTAMP, etc.)
            # PostgreSQL GENERATED ALWAYS AS ... STORED requires immutable expressions
            if re.search(r'\bCURRENT_TIMESTAMP\b|\bnow\(\)', expr, re.IGNORECASE):
                col_lines.append(f"    -- NOTE: Computed column uses volatile function, cannot be GENERATED STORED")
                col_lines.append(f"    -- Original expression: {expr}")
                col_lines.append(f"    -- Consider using a trigger or view to compute this value")
                col_lines.append(f"    {col['name']} TIMESTAMP")
            else:
                col_lines.append(f"    {col['name']} DOUBLE PRECISION GENERATED ALWAYS AS ({expr}) STORED")
            continue

        parts = [f"    {col['name']}", col['type']]

        if col.get('not_null') and "GENERATED ALWAYS AS IDENTITY" not in col['type']:
            parts.append("NOT NULL")
        elif col.get('nullable'):
            pass  # NULL is default, don't need to specify

        if col.get('default'):
            default_val = col['default']
            # Fix BOOLEAN defaults: 0 → FALSE, 1 → TRUE
            if col['type'] == 'BOOLEAN':
                if default_val in ('0', '(0)'):
                    default_val = 'FALSE'
                elif default_val in ('1', '(1)'):
                    default_val = 'TRUE'
            parts.append(f"DEFAULT {default_val}")

        col_lines.append(" ".join(parts))

    lines.append(",\n".join(col_lines))
    lines.append(");")
    lines.append("")

    return "\n".join(lines)


def generate_fdw_ddl(table_info):
    """Generate PostgreSQL CREATE FOREIGN TABLE DDL."""
    schema = table_info['schema']
    table_snake = table_info['table_snake']
    columns = table_info['columns']

    server_name = f"{schema}_server"

    lines = []
    lines.append(f"-- Foreign Table: {schema}.{table_snake}")
    lines.append(f"-- Source: SQL Server [{schema}].[{table_info['table']}]")
    lines.append(f"-- Columns: {len(columns)}")
    lines.append(f"-- FDW Server: {server_name}")
    lines.append("")
    lines.append(f"CREATE FOREIGN TABLE IF NOT EXISTS {schema}.{table_snake} (")

    col_lines = []
    for col in columns:
        if col.get('computed'):
            # FDW can't have computed columns; define as regular
            col_lines.append(f"    {col['name']} DOUBLE PRECISION")
            continue

        pg_type = col['type']
        # FDW tables can't have GENERATED ALWAYS AS IDENTITY
        if "GENERATED ALWAYS AS IDENTITY" in pg_type:
            pg_type = pg_type.replace(" GENERATED ALWAYS AS IDENTITY", "")

        parts = [f"    {col['name']}", pg_type]

        if col.get('not_null'):
            parts.append("NOT NULL")

        # FDW tables typically don't have DEFAULT

        col_lines.append(" ".join(parts))

    lines.append(",\n".join(col_lines))
    lines.append(f") SERVER {server_name}")
    lines.append(f"OPTIONS (schema_name '{schema}', table_name '{table_info['table']}');")
    lines.append("")

    return "\n".join(lines)


def main():
    source_dir = SOURCE_DIR
    target_dir = TARGET_DIR

    os.makedirs(target_dir, exist_ok=True)

    # Process all SQL files
    files = sorted([f for f in os.listdir(source_dir) if f.endswith('.sql')])

    results = []
    errors = []

    for filename in files:
        filepath = os.path.join(source_dir, filename)

        try:
            info = parse_table_file(filepath)
            if info is None:
                errors.append(f"SKIP: {filename} - could not parse")
                continue

            ddl = generate_pg_ddl(info)

            # Determine output filename
            if info['is_fdw']:
                out_name = f"{info['schema']}_{info['table_snake']}.sql"
            else:
                out_name = f"{info['table_snake']}.sql"

            out_path = os.path.join(target_dir, out_name)
            with open(out_path, 'w') as f:
                f.write(ddl)

            orig_col_count = len(info['columns'])
            results.append({
                'source': filename,
                'output': out_name,
                'schema': info['schema'],
                'table': info['table'],
                'table_pg': info['table_snake'],
                'columns': orig_col_count,
                'is_fdw': info['is_fdw']
            })

        except Exception as e:
            errors.append(f"ERROR: {filename} - {str(e)}")

    # Print summary
    print(f"\n{'='*60}")
    print(f"CONVERSION COMPLETE")
    print(f"{'='*60}")
    print(f"Tables converted: {len(results)}")
    print(f"Errors: {len(errors)}")

    dbo_count = sum(1 for r in results if not r['is_fdw'])
    fdw_count = sum(1 for r in results if r['is_fdw'])
    print(f"  DBO tables: {dbo_count}")
    print(f"  FDW tables: {fdw_count}")

    if errors:
        print(f"\nERRORS:")
        for e in errors:
            print(f"  {e}")

    # Print column count summary
    print(f"\n{'='*60}")
    print(f"COLUMN COUNT VERIFICATION")
    print(f"{'='*60}")
    print(f"{'Table':<45} {'Cols':>5} {'Schema':<8} {'FDW':>3}")
    print(f"{'-'*45} {'-'*5} {'-'*8} {'-'*3}")
    total_cols = 0
    for r in sorted(results, key=lambda x: (x['schema'], x['table_pg'])):
        fdw_flag = "YES" if r['is_fdw'] else ""
        print(f"{r['table_pg']:<45} {r['columns']:>5} {r['schema']:<8} {fdw_flag:>3}")
        total_cols += r['columns']
    print(f"{'-'*45} {'-'*5}")
    print(f"{'TOTAL':<45} {total_cols:>5}")

    # Save results as JSON for report generation
    with open('table_conversion_results.json', 'w') as f:
        json.dump({'results': results, 'errors': errors}, f, indent=2)

    return len(errors)


if __name__ == "__main__":
    sys.exit(main())
