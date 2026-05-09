#!/usr/bin/env python3
"""
generate_test_skeleton.py — produce a starter pgTAP test file from object metadata.

Reads a JSON spec describing the database object you want to test and writes a
ready-to-edit .sql test file based on the matching template.

Usage:
    python generate_test_skeleton.py --spec spec.json --out tests/

Spec format (example):

    {
      "type": "function",                    # table | function | procedure | trigger | view | rls | constraint
      "schema": "public",
      "name": "calculate_order_total",
      "args": ["integer"],                   # functions/procedures only
      "return_type": "numeric",              # functions only
      "language": "plpgsql",                 # functions/procedures only
      "trigger_table": "products",           # triggers only
      "trigger_function": "fn_log_changes",  # triggers only
      "columns": ["id", "email", "name"],    # tables/views only
      "policies": ["owner_select", "owner_insert"],  # rls only
      "description": "calculates total with 10% discount over 100"
    }

The script does NOT introspect a real database — it just fills the template
with whatever you put in the spec. After generation, edit the file to add
your actual seed data, expected values, and edge cases.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


# Map object type → template filename
TEMPLATE_MAP = {
    "table":      "test-table.sql",
    "function":   "test-function.sql",
    "procedure":  "test-procedure.sql",
    "trigger":    "test-trigger.sql",
    "view":       "test-view.sql",
    "rls":        "test-rls.sql",
    "constraint": "test-constraint.sql",
}


def find_templates_dir() -> Path:
    """Locate assets/templates/ relative to this script."""
    script_dir = Path(__file__).resolve().parent
    candidates = [
        script_dir.parent / "assets" / "templates",
        script_dir / "assets" / "templates",
    ]
    for c in candidates:
        if c.is_dir():
            return c
    sys.exit(f"❌ Templates directory not found. Searched: {candidates}")


def render(template: str, spec: dict[str, Any]) -> str:
    """Substitute spec values into the template's <PLACEHOLDER> markers."""
    result = template

    # Universal substitutions
    schema = spec.get("schema", "public")
    name = spec.get("name", "<NAME>")
    description = spec.get("description", "<BRIEF_DESCRIPTION>")
    plan_n = spec.get("plan", "N")

    result = result.replace("<SCHEMA>", schema)
    result = result.replace("<BRIEF_DESCRIPTION>", description)
    result = result.replace("<N>", str(plan_n))

    # Type-specific substitutions
    obj_type = spec.get("type")

    if obj_type == "table":
        result = result.replace("<TABLE_NAME>", name)
        result = result.replace("<TABLE>", name)
        cols = spec.get("columns", [])
        if cols:
            arr = ", ".join(f"'{c}'" for c in cols)
            result = result.replace(
                "ARRAY['<col1>', '<col2>', '<col3>']",
                f"ARRAY[{arr}]",
            )

    elif obj_type in ("function", "procedure"):
        marker = "<FUNCTION_NAME>" if obj_type == "function" else "<PROCEDURE_NAME>"
        upper = "<FUNCTION>" if obj_type == "function" else "<PROCEDURE>"
        result = result.replace(marker, name)
        result = result.replace(upper, name)
        args = spec.get("args", [])
        result = result.replace("<ARG_TYPES>", ", ".join(args))
        if args:
            arr = ", ".join(f"'{a}'" for a in args)
            result = result.replace(
                "ARRAY['<arg1_type>', '<arg2_type>']",
                f"ARRAY[{arr}]",
            )
        if spec.get("return_type"):
            result = result.replace("<return_type>", spec["return_type"])
        if spec.get("language"):
            result = result.replace("'plpgsql'", f"'{spec['language']}'", 1)

    elif obj_type == "trigger":
        result = result.replace("<TRIGGER_NAME>", name)
        result = result.replace("<TRIGGER>", name)
        if spec.get("trigger_table"):
            result = result.replace("<TABLE>", spec["trigger_table"])
        if spec.get("trigger_function"):
            result = result.replace("<TRIGGER_FUNCTION>", spec["trigger_function"])
            result = result.replace("<FUNCTION_SCHEMA>", schema)

    elif obj_type == "view":
        result = result.replace("<VIEW_NAME>", name)
        result = result.replace("<VIEW>", name)
        cols = spec.get("columns", [])
        if cols:
            arr = ", ".join(f"'{c}'" for c in cols)
            result = result.replace(
                "ARRAY['<col1>', '<col2>', '<col3>']",
                f"ARRAY[{arr}]",
            )

    elif obj_type == "rls":
        result = result.replace("<TABLE>", spec.get("table", name))
        policies = spec.get("policies", [])
        if policies:
            arr = ", ".join(f"'{p}'" for p in policies)
            result = result.replace(
                "ARRAY['<policy1>', '<policy2>']",
                f"ARRAY[{arr}]",
            )

    elif obj_type == "constraint":
        result = result.replace("<TABLE>", name)

    return result


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Generate a pgTAP test skeleton from an object spec.",
    )
    p.add_argument("--spec", required=True, help="Path to a JSON spec file.")
    p.add_argument("--out", default="tests/",
                   help="Output directory (default: tests/).")
    p.add_argument("--filename", default=None,
                   help="Override generated filename (default: test_<schema>_<name>.sql).")
    return p.parse_args()


def main() -> int:
    args = parse_args()

    spec_path = Path(args.spec).expanduser().resolve()
    if not spec_path.is_file():
        print(f"❌ Spec file not found: {spec_path}", file=sys.stderr)
        return 1

    try:
        spec = json.loads(spec_path.read_text())
    except json.JSONDecodeError as e:
        print(f"❌ Spec file is not valid JSON: {e}", file=sys.stderr)
        return 1

    obj_type = spec.get("type")
    if obj_type not in TEMPLATE_MAP:
        print(
            f"❌ Unknown object type {obj_type!r}. "
            f"Must be one of: {', '.join(sorted(TEMPLATE_MAP))}",
            file=sys.stderr,
        )
        return 1

    templates_dir = find_templates_dir()
    template_path = templates_dir / TEMPLATE_MAP[obj_type]

    if not template_path.is_file():
        print(f"❌ Template not found: {template_path}", file=sys.stderr)
        return 1

    template = template_path.read_text()
    rendered = render(template, spec)

    out_dir = Path(args.out).expanduser().resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    schema = spec.get("schema", "public")
    name = spec.get("name", "object")
    fname = args.filename or f"test_{schema}_{name}.sql"
    out_path = out_dir / fname
    out_path.write_text(rendered)

    print(f"✅ Generated {out_path}")
    print(f"   Open it and replace the <PLACEHOLDERS> with real values,")
    print(f"   add seed data, expected values, and edge cases.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
