# Sample Output: compare-versions.py

This document demonstrates the output from `compare-versions.py` for the `addarc` procedure.

---

## Terminal Output (Default)

```
================================================================================
Comparison: addarc (procedure)
================================================================================

SQL Server:  /Users/pierre.ribeiro/.../source/original/sqlserver/11. create-routine/0. perseus.dbo.AddArc.sql
  Lines: 79

PostgreSQL: /Users/pierre.ribeiro/.../source/building/pgsql/refactored/20. create-procedure/0. perseus.addarc.sql
  Lines: 419

Statistics:
  Lines added:   +417
  Lines removed: -77
  Lines changed: ~77
  Total changes: 494
  Percent changed: 117.9%
  Quality score: 7.0/10.0

Unified Diff:

--- SQL Server: 0. perseus.dbo.AddArc.sql
+++ PostgreSQL: 0. perseus.addarc.sql
@@ -1,79 +1,419 @@
-USE [perseus]
-GO
-
-CREATE PROCEDURE AddArc @MaterialUid VARCHAR(50), @TransitionUid VARCHAR(50), @Direction VARCHAR(2) AS
-
-	DECLARE @FormerDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
-	DECLARE @FormerUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
-	DECLARE @DeltaDownstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
-	DECLARE @DeltaUpstream TABLE (start_point VARCHAR(50), end_point VARCHAR(50), path VARCHAR(250), level INT, PRIMARY KEY (start_point, end_point, path))
...

+-- ============================================================================
+-- CORRECTED PROCEDURE: AddArc
+-- ============================================================================
+-- Purpose: Adds arc to material/transition graph and propagates relationships
+-- Author: Pierre Ribeiro + Claude Code Web
+-- Created: 2025-11-24
+--
+-- Migration: SQL Server T-SQL → PostgreSQL PL/pgSQL
+-- Original: procedures/original/dbo.AddArc.sql (82 lines)
+-- AWS SCT: procedures/aws-sct-converted/0. perseus_dbo.addarc.sql (262 lines)
+-- Corrected: 130 lines (50% reduction from AWS SCT bloat)
...

+CREATE OR REPLACE PROCEDURE perseus_dbo.addarc(
+    IN par_materialuid VARCHAR,
+    IN par_transitionuid VARCHAR,
+    IN par_direction VARCHAR
+)
+LANGUAGE plpgsql
+AS $BODY$
...

================================================================================
```

**Note:** In the terminal, the output uses ANSI color codes:
- Green (+) for added lines
- Red (-) for removed lines
- Yellow (~) for changed lines
- Cyan for section headers

---

## JSON Output

```json
{
  "object_name": "addarc",
  "object_type": "procedure",
  "timestamp": "2026-01-25T14:42:55.847764",
  "are_identical": false,
  "files": {
    "sqlserver": {
      "path": "/Users/pierre.ribeiro/.../source/original/sqlserver/11. create-routine/0. perseus.dbo.AddArc.sql",
      "lines": 79
    },
    "postgresql": {
      "path": "/Users/pierre.ribeiro/.../source/building/pgsql/refactored/20. create-procedure/0. perseus.addarc.sql",
      "lines": 419
    }
  },
  "statistics": {
    "lines_added": 417,
    "lines_removed": 77,
    "lines_changed": 77,
    "total_changes": 494,
    "percent_changed": 117.9
  },
  "quality_score": 7.0,
  "transformations": [],
  "unified_diff": "--- SQL Server: 0. perseus.dbo.AddArc.sql\n+++ PostgreSQL: 0. perseus.addarc.sql\n@@ -1,79 +1,419 @@\n-USE [perseus]\n-GO..."
}
```

**Use Cases:**
- Automation pipelines
- Quality gate validation
- Historical tracking
- Metrics dashboards

---

## Markdown Output

```markdown
# Comparison: addarc

**Object Type:** procedure
**Date:** 2026-01-25T14:42:55.847764
**Status:** ⚠️ Differences Found

## Files

**SQL Server:** `source/original/sqlserver/11. create-routine/0. perseus.dbo.AddArc.sql`
- Lines: 79

**PostgreSQL:** `source/building/pgsql/refactored/20. create-procedure/0. perseus.addarc.sql`
- Lines: 419

## Statistics

| Metric | Value |
|--------|-------|
| Lines added | +417 |
| Lines removed | -77 |
| Lines changed | ~77 |
| Total changes | 494 |
| Percent changed | 117.9% |
| Quality score | **7.0/10.0** |

## Unified Diff

[Diff content...]
```

**Use Cases:**
- Sprint review documentation
- Code review artifacts
- Migration status reports
- Historical records

---

## HTML Output

Generates a styled, web-viewable comparison with:

- Styled headers and metrics cards
- Color-coded statistics (green/red/yellow)
- Transformation highlights
- Syntax-highlighted diff
- Responsive design for mobile/desktop

**Preview:**

![HTML Output Preview](comparison-html-preview.png)

**Use Cases:**
- Stakeholder presentations
- Web-based documentation
- Archive for future reference
- Cross-platform sharing

---

## Batch Comparison Summary

When running batch comparisons, the tool provides a summary:

```
✓ Compared procedure addarc
✓ Compared procedure removearc
✓ Compared procedure movecontainer
✓ Compared procedure getmaterialbyrunproperties
✓ Compared procedure linkunlinkedmaterials

================================================================================
Batch Comparison Summary
================================================================================
Total objects compared: 5
Identical: 0
Different: 5
Average quality score: 8.2/10.0
```

**Output File (Markdown):**
- Individual comparison sections for each object
- Consolidated statistics table
- Navigation links
- Summary metrics

---

## Transformation Detection Examples

When T-SQL to PostgreSQL transformations are detected, they are listed:

```
Transformations Applied:
  • Data type conversion: 12 occurrence(s)
    SQL Server: NVARCHAR(100)
    PostgreSQL: VARCHAR(100)

  • Function replacement: 4 occurrence(s)
    SQL Server: GETDATE()
    PostgreSQL: CURRENT_TIMESTAMP

  • Temporary table syntax: 6 occurrence(s)
    SQL Server: CREATE TABLE #temp
    PostgreSQL: CREATE TEMPORARY TABLE tmp_temp

  • String concatenation operator: 8 occurrence(s)
    SQL Server: path + delimiter
    PostgreSQL: path || delimiter
```

---

## Quality Score Interpretation

| Score | Assessment | Typical Characteristics |
|-------|-----------|-------------------------|
| 9-10 | Excellent | Minimal changes, clean conversion, no major refactoring |
| 7-8 | Good | Reasonable changes, documented transformations, constitution compliance |
| 5-6 | Acceptable | Significant changes, may need review, some manual refactoring |
| 3-4 | Poor | Excessive changes, requires investigation, potential over-engineering |
| 0-2 | Critical | Complete rewrite, logic changes, high risk |

**For the addarc example:**
- **Score: 7.0/10.0** = Good
- Large line count increase (79 → 419) due to:
  - Comprehensive error handling added
  - Detailed logging and comments
  - Constitution compliance improvements
  - Defensive programming (input validation)
- Acceptable for production deployment

---

## Side-by-Side Comparison (Terminal)

```
================================================================================
SQL Server                                       | PostgreSQL
================================================================================
CREATE PROCEDURE AddArc @MaterialUid VARCHAR...  | CREATE OR REPLACE PROCEDURE perseus_dbo.addarc(
                                                 |     IN par_materialuid VARCHAR,
                                                 |     IN par_transitionuid VARCHAR,
DECLARE @FormerDownstream TABLE (...)            | CREATE TEMPORARY TABLE former_downstream (
  start_point VARCHAR(50),                       |   start_point VARCHAR(50),
  end_point VARCHAR(50),                         |   end_point VARCHAR(50),
  path VARCHAR(250),                             |   path VARCHAR(250),
  level INT,                                     |   level INTEGER,
  PRIMARY KEY (start_point, end_point, path)     |   PRIMARY KEY (start_point, end_point, path)
)                                                | ) ON COMMIT DROP;
...
```

**Benefits:**
- Quick visual inspection
- Easy to spot structural changes
- Ideal for line-by-line review
- Terminal-friendly (no GUI needed)

---

## Exit Code Usage Examples

### Validation Script

```bash
#!/bin/bash
# validate-conversion.sh

python3 scripts/automation/compare-versions.py procedure addarc

EXIT_CODE=$?

case $EXIT_CODE in
  0)
    echo "✓ Files are identical - no changes needed"
    ;;
  1)
    echo "⚠️ Differences found - review required"
    ;;
  2)
    echo "❌ Invalid arguments - check command syntax"
    exit 2
    ;;
  3)
    echo "❌ File not found - verify object name"
    exit 3
    ;;
esac
```

### CI/CD Quality Gate

```bash
#!/bin/bash
# quality-gate.sh

OBJECT_TYPE=$1
OBJECT_NAME=$2

python3 scripts/automation/compare-versions.py \
  $OBJECT_TYPE $OBJECT_NAME \
  --format json > /tmp/comparison.json

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "✓ No changes detected - proceeding"
  exit 0
elif [ $EXIT_CODE -eq 1 ]; then
  QUALITY_SCORE=$(jq -r '.quality_score' /tmp/comparison.json)
  if (( $(echo "$QUALITY_SCORE >= 7.0" | bc -l) )); then
    echo "✓ Quality gate passed: $QUALITY_SCORE/10.0"
    exit 0
  else
    echo "❌ Quality gate failed: $QUALITY_SCORE/10.0 (minimum: 7.0)"
    exit 1
  fi
else
  echo "❌ Comparison failed with exit code $EXIT_CODE"
  exit $EXIT_CODE
fi
```

---

**Generated:** 2026-01-25
**Tool Version:** 1.0
**Sample Object:** addarc (procedure)
