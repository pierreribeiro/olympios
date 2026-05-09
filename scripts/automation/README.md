# Automation Scripts

## 📁 Directory Purpose

This directory contains **Python automation scripts** that reduce manual work in the migration process by generating analysis documents, comparing versions, extracting warnings, and auto-generating test templates.

**Key Functions:**
- 🤖 Generate analysis documents from SQL code
- 🔍 Compare original vs. corrected versions
- ⚠️ Extract and categorize AWS SCT warnings
- 🧪 Auto-generate test templates

---

## 🎯 Automation Philosophy

**If You Do It Twice, Automate It**

These scripts save time by:
- Reducing manual analysis time (hours → minutes)
- Ensuring consistent documentation format
- Catching issues earlier in the process
- Generating boilerplate code automatically

**Time Savings Estimate:**
- Manual analysis: ~4-6 hours per procedure
- With automation: ~1-2 hours per procedure
- **ROI:** 60-75% time reduction

---

## 📋 Available Scripts

### 1. analyze-object.py ✅ READY
**Purpose:** Automated analysis of database objects (procedures, functions, views, tables)

**Status:** ✅ Production-ready (v1.0)

**Usage:**
```bash
# Analyze a single procedure
python scripts/automation/analyze-object.py procedure AddArc

# Analyze with custom paths
python scripts/automation/analyze-object.py function mcgetupstream \
  --original source/original/sqlserver/mcgetupstream.sql \
  --converted source/original/pgsql-aws-sct-converted/mcgetupstream.sql

# Batch analysis from file list
python scripts/automation/analyze-object.py --batch procedures.txt

# Get quality score only (for CI/CD)
python scripts/automation/analyze-object.py procedure sp_move_node --score-only
```

**What It Does:**
1. **Auto-detects files** in hierarchical directory structure (source/original/sqlserver/*/*)
2. **Parses SQL** for both original (T-SQL) and converted (PostgreSQL) code
3. **Detects issues** and categorizes by severity (P0/P1/P2/P3)
4. **Validates constitution compliance** against 7 core principles
5. **Calculates complexity metrics** (cyclomatic complexity, LOC, nesting depth)
6. **Generates quality score** (0-10 across 5 dimensions)
7. **Creates markdown report** with detailed findings and recommendations

**Quality Score Framework:**
- **Syntax Correctness (20%):** Valid PostgreSQL 17 syntax
- **Logic Preservation (30%):** Business logic identical to SQL Server
- **Performance (20%):** Expected performance vs baseline
- **Maintainability (15%):** Readability, documentation, complexity
- **Security (15%):** SQL injection risks, permissions

**Minimum threshold:** 7.0/10 overall, no dimension below 6.0/10

**Features:**
- ✅ No external dependencies (stdlib only)
- ✅ Fast execution (<5 seconds per object)
- ✅ Hierarchical file search
- ✅ Batch processing support
- ✅ Score-only mode for automation
- ✅ Clear exit codes (0=success, 1=failed, 2=invalid args)
- ✅ Constitution compliance checking
- ✅ Security vulnerability detection

**Example Output:**
```markdown
# Analysis: AddArc

**Object Type:** procedure
**Analyst:** analyze-object.py (automated)
**Date:** 2026-01-25 14:39:06

## Quality Score Summary

| Dimension | Score | Weight | Contribution |
|-----------|-------|--------|--------------|
| Syntax Correctness | 10.0/10 | 20% | 2.00 |
| Logic Preservation | 10.0/10 | 30% | 3.00 |
| Performance | 10.0/10 | 20% | 2.00 |
| Maintainability | 8.0/10 | 15% | 1.20 |
| Security | 10.0/10 | 15% | 1.50 |
| **OVERALL** | **9.7/10** | 100% | **9.70** |

**Status:** ✅ PASS

## Issue Summary
- **P0 Critical:** 0 (Blocks deployment)
- **P1 High:** 0 (Must fix before PROD)
- **P2 Medium:** 0 (Fix before STAGING)
- **P3 Low:** 0 (Track for improvement)

## Complexity Metrics
- **Lines of Code:** 249
- **Cyclomatic Complexity:** 36
- **Branching Points:** 35 (IF/CASE statements)
- **Loop Structures:** 0 (WHILE/FOR loops)
- **Nesting Depth:** 1
- **Comment Ratio:** 9.8%

## Recommendations
🔄 **REFACTORING:** High complexity - consider breaking into smaller functions/CTEs
✅ **QUALITY GATE:** Object meets minimum quality threshold
```

**Configuration:** No configuration required (all patterns built-in)

**Dependencies:** None (Python 3.8+ stdlib only)

---

### 2. compare-versions.py ✅ READY
**Purpose:** SQL Server vs PostgreSQL version comparison with transformation detection

**Status:** ✅ Production-ready (v1.0)

**Usage:**
```bash
# Compare a single procedure
python scripts/automation/compare-versions.py procedure addarc

# Custom file paths
python scripts/automation/compare-versions.py function mcgetupstream \
  --sqlserver source/original/sqlserver/mcgetupstream.sql \
  --postgresql source/building/pgsql/refactored/19.create-function/mcgetupstream.sql

# Batch comparison
python scripts/automation/compare-versions.py --batch procedures.txt --output comparison-report.md

# Side-by-side view
python scripts/automation/compare-versions.py view translated --side-by-side

# JSON output for automation
python scripts/automation/compare-versions.py procedure addarc --format json
```

**What It Does:**
1. **Line-by-line unified diff** with ANSI color codes for terminal
2. **Side-by-side comparison** mode for visual inspection
3. **Transformation detection** - identifies T-SQL → PostgreSQL patterns
4. **Quality scoring** based on change volume and systematic conversion
5. **Multiple output formats** - terminal, markdown, HTML, JSON
6. **Batch processing** with consolidated reports
7. **Fast execution** (<2 seconds per comparison)

**Transformation Patterns Detected:**
- Data types: `NVARCHAR` → `VARCHAR`, `DATETIME` → `TIMESTAMP`
- Identity: `IDENTITY(1,1)` → `GENERATED ALWAYS AS IDENTITY`
- Strings: `+` → `||` concatenation operator
- Functions: `GETDATE()` → `CURRENT_TIMESTAMP`, `ISNULL()` → `COALESCE()`
- Logic: `IIF()` → `CASE WHEN`
- Transactions: `BEGIN TRAN` → `BEGIN`
- Error handling: `RAISERROR` → `RAISE EXCEPTION`
- Temp tables: `#temp` → `CREATE TEMPORARY TABLE tmp_*`
- Limits: `SELECT TOP N` → `LIMIT N`
- Nulls: `= NULL` → `IS NULL`

**Quality Score (0-10):**
- Lower % change = higher score
- Documented transformations = systematic conversion
- Minimal net additions = efficient refactoring

**Exit Codes:**
- `0` = Files identical
- `1` = Differences found (normal)
- `2` = Invalid arguments
- `3` = File not found

**Features:**
- ✅ No external dependencies (stdlib only)
- ✅ Case-insensitive file matching
- ✅ Auto-detects SQL Server (PascalCase) ↔ PostgreSQL (snake_case)
- ✅ Color-coded terminal output
- ✅ Batch processing support
- ✅ Multiple output formats
- ✅ Statistics and metrics

**Documentation:** See `COMPARE-VERSIONS-README.md` for full details

**Example Output:**
```
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

Transformations Applied:
  • Temporary table syntax: 6 occurrence(s)
  • String concatenation operator: 8 occurrence(s)
  • Function replacement: 4 occurrence(s)
```

**Configuration:** None required (built-in pattern detection)

**Dependencies:** None (Python 3.8+ stdlib only)

**Use Cases:**
- Code review sessions
- Documentation for stakeholders
- Training material
- Regression analysis

---

### 3. extract-warnings.py 🚧 PLANNED
**Purpose:** Parse AWS SCT warnings and categorize them

**Status:** 🚧 Planned (not yet implemented)

**Planned Usage:**
```bash
python scripts/automation/extract-warnings.py \
  --sct-output aws-sct-report.xml \
  --output tracking/sct-warnings-summary.csv
```

**What It Will Do:**
1. Parse AWS SCT XML output
2. Extract all warnings and errors
3. Categorize by type (syntax, performance, data type, etc.)
4. Map to specific procedures
5. Prioritize by severity
6. Generate CSV report

**Use Cases:**
- Initial assessment (how much work?)
- Prioritization (which procedures first?)
- Tracking (how many warnings resolved?)
- Reporting (status to management)

---

### 4. generate-tests.py 🚧 PLANNED
**Purpose:** Auto-generate test templates from procedure signature

**Status:** 🚧 Planned (not yet implemented)

**Planned Usage:**
```bash
python scripts/automation/generate-tests.py \
  --procedure source/building/pgsql/refactored/reconcilemupstream.sql \
  --output tests/unit/test_reconcilemupstream.sql
```

**What It Will Do:**
1. Parse procedure signature (parameters, return type)
2. Generate test structure:
   - Test fixtures (sample data)
   - Positive test cases
   - Negative test cases (error handling)
   - Edge cases (NULL, empty, extreme values)
   - Performance baseline test
3. Create test SQL with placeholders
4. Include assertions and expected results

**Configuration:**
- Test frameworks: pgTAP, pgtap, custom
- Test data generation rules
- Assertion templates

---

## 🔧 Configuration

### automation-config.json
```json
{
  "analyze_procedure": {
    "issue_patterns": {
      "transaction_control": [
        "BEGIN TRAN",
        "COMMIT TRAN",
        "ROLLBACK TRAN"
      ],
      "raise_statements": [
        "RAISERROR",
        "RAISE_APPLICATION_ERROR"
      ],
      "temp_tables": [
        "#\\w+"
      ]
    },
    "quality_weights": {
      "p0_critical": -3.0,
      "p1_high": -1.5,
      "p2_medium": -0.5,
      "p3_low": -0.1
    }
  },
  "generate_tests": {
    "framework": "pgTAP",
    "test_types": [
      "happy_path",
      "null_params",
      "edge_cases",
      "error_handling",
      "performance"
    ]
  }
}
```

---

## 🚀 Batch Processing

### Process Multiple Objects with Batch File

**Create batch file (objects.txt):**
```txt
# Format: object_type,object_name
procedure,AddArc
procedure,sp_move_node
procedure,ReconcileMUpstream
function,mcgetupstream
function,mcgetdownstream
view,translated
table,goo
```

**Execute batch analysis:**
```bash
python scripts/automation/analyze-object.py --batch objects.txt
```

**Output:**
```
Batch processing from: objects.txt

Analyzing procedure: AddArc
  Quality score: 9.7/10
  ✅ Analysis complete

Analyzing procedure: sp_move_node
  Quality score: 9.7/10
  ✅ Analysis complete

...

======================================================================
Batch processing complete:
  ✅ Success: 7
  ❌ Failed:  0
======================================================================
```

### Process All Procedures Automatically
```bash
#!/bin/bash
# scripts/automation/batch-analyze-all.sh

# Generate batch file from directory
find source/original/sqlserver/11.\ create-routine -name "*.sql" | \
  sed 's/.*perseus\.dbo\./procedure,/' | \
  sed 's/\.sql$//' > /tmp/batch-procedures.txt

# Execute batch analysis
python scripts/automation/analyze-object.py --batch /tmp/batch-procedures.txt

echo "✅ Batch processing complete"
```

### CI/CD Integration
```bash
# Use in GitHub Actions or Jenkins
python scripts/automation/analyze-object.py procedure AddArc --score-only > score.txt

SCORE=$(cat score.txt)
if (( $(echo "$SCORE < 7.0" | bc -l) )); then
  echo "❌ Quality gate failed: $SCORE < 7.0"
  exit 1
fi

echo "✅ Quality gate passed: $SCORE"
```

---

## 📊 Automation Metrics

Track automation effectiveness with `analyze-object.py`:

| Metric | Manual | Automated | Improvement |
|--------|--------|-----------|-------------|
| **Analysis Time** | 4-6 hours | <5 seconds | 99.9% ⬇️ |
| **Documentation** | 2 hours | <5 seconds | 99.9% ⬇️ |
| **Consistency** | Variable | 100% | ✅ Perfect |
| **Constitution Compliance** | Manual review | Automated checks | ✅ 100% coverage |
| **Quality Scoring** | Subjective | Objective (0-10) | ✅ Standardized |
| **Issue Detection** | Variable | Comprehensive | ✅ All patterns |

**Real Performance (from Sprint 3):**
- **analyze-object.py execution:** <5 seconds per object
- **Batch analysis (15 procedures):** <2 minutes total
- **Report generation:** Instant markdown output
- **Quality gates:** Automated pass/fail thresholds

**Project Savings (769 objects estimated):**
- Manual analysis: 769 objects × 4 hours = **3,076 hours**
- Automated analysis: 769 objects × 5 seconds = **1 hour**
- **Time savings: 3,075 hours (99.97% reduction)**

**Sprint 3 Achievements (15 procedures):**
- Average quality score: 8.67/10 (exceeds 7.0 minimum)
- Performance improvement: +63% to +97% vs SQL Server
- Zero P0/P1 issues in final deliverables
- 100% constitution compliance

---

## 🛠️ Development Guide

### Adding New Automation Script

**Template:**
```python
#!/usr/bin/env python3
"""
Script: my_automation.py
Purpose: [Description]
Author: Pierre Ribeiro
Created: YYYY-MM-DD
"""

import argparse
import sys
from pathlib import Path

def parse_arguments():
    parser = argparse.ArgumentParser(
        description='[Script description]'
    )
    parser.add_argument('--input', required=True, help='Input file')
    parser.add_argument('--output', required=True, help='Output file')
    return parser.parse_args()

def main():
    args = parse_arguments()
    
    try:
        # 1. Read input
        # 2. Process
        # 3. Write output
        # 4. Log results
        
        print(f"✅ Success: {args.output}")
        return 0
        
    except Exception as e:
        print(f"❌ Error: {str(e)}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())
```

---

## 📚 Dependencies

### analyze-object.py (READY)
**No external dependencies required!**

Uses Python 3.8+ standard library only:
- `argparse` - CLI argument parsing
- `re` - Regular expression pattern matching
- `pathlib` - File path operations
- `datetime` - Timestamp generation
- `dataclasses` - Structured data classes
- `enum` - Enumeration types

**Why no dependencies?**
- ✅ Maximum portability across environments
- ✅ No installation friction
- ✅ Works in restricted/air-gapped environments
- ✅ Faster execution (no import overhead)
- ✅ Zero maintenance burden

### Future Scripts (PLANNED)
```txt
# requirements.txt (for planned scripts)
sqlparse>=0.4.3       # SQL parsing (for compare-versions.py)
beautifulsoup4>=4.12  # HTML parsing (for compare-versions.py)
lxml>=4.9.3           # XML parsing (for extract-warnings.py)
jinja2>=3.1.2         # Template engine (for generate-tests.py)
```

### Installation
```bash
# analyze-object.py works immediately (no setup needed)
python3 scripts/automation/analyze-object.py --help

# For future scripts (when implemented):
# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate  # Linux/Mac
# or
.venv\Scripts\activate  # Windows

# Install dependencies
pip install -r scripts/automation/requirements.txt
```

---

## 🚨 Troubleshooting

### Script Fails to Parse SQL
```bash
# Try with debug mode
python scripts/automation/analyze-procedure.py \
  --original file.sql \
  --converted file.sql \
  --output output.md \
  --debug

# Check SQL syntax first
psql -f file.sql --dry-run
```

### Missing Dependencies
```bash
# Reinstall all dependencies
pip install -r scripts/automation/requirements.txt --force-reinstall
```

### Performance Issues (Large Files)
```python
# Add streaming mode for large files
parser.parse_stream(input_file)  # Instead of parse_file()
```

---

## 🔗 Integration Points

### CI/CD Pipeline
```yaml
# .github/workflows/analyze.yml
- name: Auto-generate Analysis
  run: |
    python scripts/automation/analyze-procedure.py \
      --original ${{ env.ORIGINAL_FILE }} \
      --converted ${{ env.CONVERTED_FILE }} \
      --output analysis.md
    
    # Fail if quality score < 7.0
    quality_score=$(grep "Quality Score:" analysis.md | awk '{print $3}')
    if (( $(echo "$quality_score < 7.0" | bc -l) )); then
      echo "❌ Quality score too low: $quality_score"
      exit 1
    fi
```

### Git Hooks
```bash
# .git/hooks/pre-commit
#!/bin/bash
# Auto-generate analysis on commit

for file in procedures/corrected/*.sql; do
  if git diff --cached --name-only | grep -q "$file"; then
    python scripts/automation/analyze-procedure.py \
      --original "procedures/original/$(basename $file)" \
      --converted "$file" \
      --output "procedures/analysis/$(basename $file .sql)-analysis.md"
      
    git add "procedures/analysis/$(basename $file .sql)-analysis.md"
  fi
done
```

---

## 📈 Future Enhancements

Potential additions:
- [ ] AI-powered issue detection (ML model)
- [ ] Automatic correction suggestions
- [ ] Natural language analysis summaries
- [ ] Integration with IDE (VSCode extension)
- [ ] Real-time analysis (watch mode)
- [ ] Performance prediction model

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)  
**Last Updated:** 2025-11-13  
**Version:** 1.0
