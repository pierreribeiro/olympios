# compare-versions.py - SQL Server vs PostgreSQL Comparison Tool

## Overview

`compare-versions.py` is a comprehensive tool for comparing SQL Server original database objects with their PostgreSQL converted counterparts. It provides side-by-side analysis, transformation detection, quality scoring, and multiple output formats.

**Created:** 2026-01-25
**Task:** T023 - Version comparison tool
**Author:** Pierre Ribeiro (DBA/DBRE)
**Version:** 1.0

---

## Features

### Core Capabilities

- **Line-by-line unified diff** with color-coded terminal output
- **Side-by-side comparison** mode for easy visual inspection
- **Structural comparison** of function signatures, table schemas, and indexes
- **Transformation analysis** - automatically detects T-SQL to PostgreSQL conversions
- **Quality assessment** with detailed statistics and scoring (0-10 scale)
- **Multiple output formats** - terminal, markdown, HTML, JSON
- **Batch processing** - compare multiple objects with consolidated reports
- **Fast execution** - <2 seconds per comparison

### Transformation Detection

Automatically identifies and counts common T-SQL to PostgreSQL transformations:

- Data type conversions (`NVARCHAR` → `VARCHAR`, `DATETIME` → `TIMESTAMP`, etc.)
- Identity columns (`IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`)
- String concatenation (`+` → `||`)
- Function replacements (`GETDATE()` → `CURRENT_TIMESTAMP`, `ISNULL()` → `COALESCE()`)
- Conditional logic (`IIF()` → `CASE WHEN`)
- Transaction syntax (`BEGIN TRAN` → `BEGIN`)
- Error handling (`RAISERROR` → `RAISE EXCEPTION`)
- Temp tables (`#temp` → `CREATE TEMPORARY TABLE tmp_*`)
- Row limiting (`SELECT TOP N` → `LIMIT N`)
- Null comparison (`= NULL` → `IS NULL`)

---

## Installation

### Prerequisites

- Python 3.8+
- Standard library only (no external dependencies)

### Setup

```bash
# Make executable
chmod +x scripts/automation/compare-versions.py

# Verify installation
python3 scripts/automation/compare-versions.py --help
```

---

## Usage

### Basic Single Object Comparison

Compare a procedure (auto-detects file locations):

```bash
python3 scripts/automation/compare-versions.py procedure addarc
```

Compare a function:

```bash
python3 scripts/automation/compare-versions.py function mcgetupstream
```

Compare a view:

```bash
python3 scripts/automation/compare-versions.py view translated
```

### Custom File Paths

Explicitly specify file locations:

```bash
python3 scripts/automation/compare-versions.py function mcgetupstream \
  --sqlserver source/original/sqlserver/11.create-routine/mcgetupstream.sql \
  --postgresql source/building/pgsql/refactored/19.create-function/mcgetupstream.sql
```

### Output Formats

#### Terminal (default) - Color-coded diff

```bash
python3 scripts/automation/compare-versions.py procedure addarc
```

#### Markdown - Documentation-ready report

```bash
python3 scripts/automation/compare-versions.py procedure addarc \
  --format markdown \
  --output reports/addarc-comparison.md
```

#### HTML - Web-viewable side-by-side

```bash
python3 scripts/automation/compare-versions.py procedure addarc \
  --format html \
  --output reports/addarc-comparison.html
```

#### JSON - Machine-readable for automation

```bash
python3 scripts/automation/compare-versions.py procedure addarc \
  --format json \
  --output reports/addarc-comparison.json
```

### Batch Processing

Create a batch file (`procedures-batch.txt`):

```text
# Format: object_type object_name (one per line)
procedure addarc
procedure removearc
procedure movecontainer
procedure getmaterialbyrunproperties
function mcgetupstream
function mcgetdownstream
view translated
```

Run batch comparison:

```bash
python3 scripts/automation/compare-versions.py \
  --batch procedures-batch.txt \
  --output batch-comparison-report.md \
  --format markdown
```

### Display Options

#### Show only statistics (no diff)

```bash
python3 scripts/automation/compare-versions.py procedure addarc --no-diff
```

#### Side-by-side terminal view

```bash
python3 scripts/automation/compare-versions.py procedure addarc --side-by-side
```

#### Specify base directory

```bash
python3 scripts/automation/compare-versions.py procedure addarc \
  --base-dir /path/to/migration/project
```

---

## Output Details

### Terminal Output

Color-coded for easy reading:

- **File Info** - Cyan headers with file paths and line counts
- **Statistics** - Green (+additions), Red (-removals), Yellow (~changes)
- **Transformations** - List of detected conversions with counts
- **Unified Diff** - Standard diff format with color highlighting

### Quality Score (0-10 scale)

Estimated conversion quality based on:

- **Change volume** - Lower % change = higher score
- **Documented transformations** - Shows systematic conversion
- **Net additions** - Penalizes excessive over-engineering

**Interpretation:**
- **9-10**: Excellent - Minimal changes, clean conversion
- **7-8**: Good - Reasonable changes, documented transformations
- **5-6**: Acceptable - Significant changes, may need review
- **<5**: Poor - Excessive changes, requires investigation

### Statistics Reported

| Metric | Description |
|--------|-------------|
| Lines added | New lines in PostgreSQL version |
| Lines removed | Lines from SQL Server not in PostgreSQL |
| Lines changed | Min(added, removed) - estimated modifications |
| Total changes | Added + removed |
| Percent changed | (Total changes / max lines) × 100 |
| Quality score | Estimated conversion quality (0-10) |

---

## Exit Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 0 | Files are identical | Validation - no changes needed |
| 1 | Differences found (normal) | Standard comparison result |
| 2 | Invalid arguments | Check command syntax |
| 3 | File not found | Verify file paths / object names |

---

## File Discovery Logic

### SQL Server Files

Searches in order:
1. `source/original/sqlserver/11. create-routine/` (procedures/functions)
2. `source/original/sqlserver/14. create-table/` (tables)
3. `source/original/sqlserver/15. create-view/` (views)
4. `source/original/sqlserver/` (fallback)

**Naming:** PascalCase (e.g., `AddArc`, `GetMaterial`)

### PostgreSQL Files

Searches by object type:
- **Procedures:** `source/building/pgsql/refactored/20. create-procedure/`
- **Functions:** `source/building/pgsql/refactored/19. create-function/`
- **Views:** `source/building/pgsql/refactored/15. create-view/`
- **Tables:** `source/building/pgsql/refactored/14. create-table/`

**Naming:** snake_case (e.g., `addarc`, `get_material`)

**Case-insensitive matching:** Automatically handles `AddArc` ↔ `addarc` conversions.

---

## Examples

### Example 1: Quick Statistics Check

```bash
$ python3 scripts/automation/compare-versions.py procedure addarc --no-diff

================================================================================
Comparison: addarc (procedure)
================================================================================

SQL Server:  source/original/sqlserver/11. create-routine/0. perseus.dbo.AddArc.sql
  Lines: 79

PostgreSQL: source/building/pgsql/refactored/20. create-procedure/0. perseus.addarc.sql
  Lines: 419

Statistics:
  Lines added:   +417
  Lines removed: -77
  Lines changed: ~77
  Total changes: 494
  Percent changed: 117.9%
  Quality score: 7.0/10.0

================================================================================
```

### Example 2: Markdown Report Generation

```bash
$ python3 scripts/automation/compare-versions.py procedure addarc \
    --format markdown --output addarc-comparison.md

Markdown report written to: addarc-comparison.md
```

### Example 3: Batch Comparison with JSON Output

```bash
$ python3 scripts/automation/compare-versions.py \
    --batch all-procedures.txt \
    --format json \
    --output batch-results.json

✓ Compared procedure addarc
✓ Compared procedure removearc
✓ Compared procedure movecontainer
...
Batch report written to: batch-results.json

================================================================================
Batch Comparison Summary
================================================================================
Total objects compared: 15
Identical: 0
Different: 15
Average quality score: 8.2/10.0
```

### Example 4: Side-by-Side Inspection

```bash
$ python3 scripts/automation/compare-versions.py procedure addarc --side-by-side

================================================================================
SQL Server                                       | PostgreSQL
================================================================================
CREATE PROCEDURE AddArc @MaterialUid VARCHAR...  | CREATE OR REPLACE PROCEDURE perseus_dbo.addarc(
                                                 | -- Variable declarations
DECLARE @FormerDownstream TABLE (...)            | CREATE TEMPORARY TABLE former_downstream (...
...
```

---

## Integration with Migration Workflow

### Step 1: Initial Analysis

After converting an object with AWS SCT:

```bash
python3 scripts/automation/compare-versions.py procedure <name> --no-diff
```

Review quality score and statistics.

### Step 2: Detailed Review

Generate markdown report for documentation:

```bash
python3 scripts/automation/compare-versions.py procedure <name> \
  --format markdown \
  --output docs/comparisons/<name>-comparison.md
```

### Step 3: Validation

After manual correction, re-run comparison to verify improvements:

```bash
# Before correction
python3 scripts/automation/compare-versions.py procedure <name> --no-diff
# Quality score: 5.5/10.0

# After correction
python3 scripts/automation/compare-versions.py procedure <name> --no-diff
# Quality score: 8.2/10.0 ✓
```

### Step 4: Sprint Review

Generate batch report for all objects in sprint:

```bash
python3 scripts/automation/compare-versions.py \
  --batch sprint3-objects.txt \
  --output sprint3-comparison-report.md
```

---

## Automation Examples

### CI/CD Pipeline Integration

```bash
#!/bin/bash
# quality-gate-check.sh

OBJECT_TYPE=$1
OBJECT_NAME=$2
MIN_QUALITY_SCORE=7.0

# Run comparison and extract quality score
RESULT=$(python3 scripts/automation/compare-versions.py \
  $OBJECT_TYPE $OBJECT_NAME \
  --format json)

QUALITY_SCORE=$(echo $RESULT | jq -r '.quality_score')

# Check against threshold
if (( $(echo "$QUALITY_SCORE < $MIN_QUALITY_SCORE" | bc -l) )); then
  echo "❌ Quality gate failed: $QUALITY_SCORE < $MIN_QUALITY_SCORE"
  exit 1
else
  echo "✓ Quality gate passed: $QUALITY_SCORE >= $MIN_QUALITY_SCORE"
  exit 0
fi
```

### Bulk Analysis Script

```bash
#!/bin/bash
# analyze-all-procedures.sh

PROCEDURES=$(ls source/building/pgsql/refactored/20.create-procedure/*.sql)

for proc_file in $PROCEDURES; do
  PROC_NAME=$(basename "$proc_file" .sql | sed 's/.*\.//')

  echo "Analyzing: $PROC_NAME"

  python3 scripts/automation/compare-versions.py \
    procedure $PROC_NAME \
    --format json \
    --output "reports/comparisons/${PROC_NAME}.json"
done

echo "Batch analysis complete: $(echo $PROCEDURES | wc -l) procedures"
```

---

## Troubleshooting

### Issue: "File not found"

**Cause:** Object name doesn't match files or base directory is incorrect.

**Solution:**
```bash
# Verify file exists
find source -name "*addarc*" -o -name "*AddArc*"

# Use explicit paths
python3 scripts/automation/compare-versions.py procedure addarc \
  --sqlserver source/original/sqlserver/11.create-routine/0.perseus.dbo.AddArc.sql \
  --postgresql source/building/pgsql/refactored/20.create-procedure/0.perseus.addarc.sql
```

### Issue: "Invalid arguments"

**Cause:** Missing required positional arguments.

**Solution:**
```bash
# Must specify both object_type and object_name
python3 scripts/automation/compare-versions.py procedure addarc
# NOT: python3 scripts/automation/compare-versions.py addarc
```

### Issue: "Permission denied"

**Cause:** Script not executable or wrong Python version.

**Solution:**
```bash
chmod +x scripts/automation/compare-versions.py
python3 --version  # Should be 3.8+
```

---

## Performance

- **Single comparison:** <2 seconds
- **Batch comparison (15 objects):** <20 seconds
- **Memory usage:** <50 MB (handles large files efficiently)

---

## Related Tools

- **analyze-object.py** - Comprehensive object analysis with constitution compliance checking
- **syntax-check.sh** - PostgreSQL syntax validation
- **dependency-check.sql** - Dependency validation

---

## Future Enhancements (Backlog)

- [ ] Semantic diff (ignore comments/whitespace)
- [ ] Visual diff in browser (HTML renderer)
- [ ] Historical comparison tracking
- [ ] Integration with quality score database
- [ ] PDF report generation
- [ ] Regression detection (compare multiple versions over time)

---

## Support

**Issues:** Report to Pierre Ribeiro (DBA/DBRE)
**Documentation:** This file + inline `--help`
**Source:** `scripts/automation/compare-versions.py`

---

## License

Internal tool for Perseus Database Migration project.
Not for external distribution.

---

**Last Updated:** 2026-01-25
**Maintained By:** Pierre Ribeiro
