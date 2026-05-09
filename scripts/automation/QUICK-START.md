# analyze-object.py - Quick Start Guide

## 🚀 5-Minute Quick Start

### Install
**None required!** Script uses Python 3.8+ standard library only.

### Test Installation
```bash
python3 scripts/automation/analyze-object.py --help
```

### Basic Usage

#### 1. Analyze Single Object
```bash
# Auto-detect file paths
python3 scripts/automation/analyze-object.py procedure AddArc

# Output:
# Analyzing procedure: AddArc
#   Original:  source/original/sqlserver/11. create-routine/0. perseus.dbo.AddArc.sql
#   Converted: source/original/pgsql-aws-sct-converted/19. create-function/0. perseus.addarc.sql
#   Complexity: 36 (LOC: 249)
#   Issues found: 0
#   Quality score: 9.7/10
#
# ✅ Analysis complete
#    Report: source/building/pgsql/refactored/analysis-reports/AddArc-analysis.md
#    Quality: 9.7/10 (PASS)
```

#### 2. Batch Analysis
Create a batch file `objects.txt`:
```txt
procedure,AddArc
procedure,sp_move_node
function,mcgetupstream
```

Run batch analysis:
```bash
python3 scripts/automation/analyze-object.py --batch objects.txt
```

#### 3. CI/CD Integration (Score Only)
```bash
# Get quality score for automation
SCORE=$(python3 scripts/automation/analyze-object.py procedure AddArc --score-only)

if (( $(echo "$SCORE < 7.0" | bc -l) )); then
  echo "❌ Quality gate failed: $SCORE"
  exit 1
fi

echo "✅ Quality gate passed: $SCORE"
```

## 📊 Understanding Quality Scores

### Score Dimensions (5)
1. **Syntax Correctness (20%)** - Valid PostgreSQL 17 syntax
2. **Logic Preservation (30%)** - Business logic identical to SQL Server
3. **Performance (20%)** - Expected performance vs baseline
4. **Maintainability (15%)** - Readability, documentation, complexity
5. **Security (15%)** - SQL injection risks, permissions

### Pass/Fail Thresholds
- **Overall score:** Must be ≥ 7.0/10
- **Each dimension:** Must be ≥ 6.0/10
- **Both conditions** must be met to pass

### Example: Why 8.2/10 Can Fail
```
Overall: 8.2/10 ✅ (above 7.0)
BUT:
  Logic Preservation: 5.0/10 ❌ (below 6.0)

Result: ❌ FAIL
```

## 🔍 Issue Severity Levels

| Severity | Description | Action Required | Score Impact |
|----------|-------------|-----------------|--------------|
| **P0 Critical** | Blocks deployment | Fix immediately | -3.0 per issue |
| **P1 High** | Must fix before PROD | Fix before production | -1.5 per issue |
| **P2 Medium** | Must fix before STAGING | Fix before staging | -0.5 per issue |
| **P3 Low** | Track for improvement | Fix when convenient | -0.1 per issue |

## 📋 Common Issues Detected

### P0 Issues (Critical)
- ✅ T-SQL temp table syntax (`#temp`) not converted
- ✅ RAISERROR not converted to RAISE EXCEPTION
- ✅ Dynamic SQL without quote_ident/quote_literal (SQL injection risk)
- ✅ Cursors violating set-based execution

### P1 Issues (High)
- ✅ BEGIN TRAN should be BEGIN (PostgreSQL)
- ✅ IIF() should be CASE WHEN ... END
- ✅ WHILE loops violating set-based execution
- ✅ Implicit NULL comparisons (= NULL instead of IS NULL)

### P2 Issues (Medium)
- ✅ SELECT * prohibited (enumerate columns)
- ✅ WHEN OTHERS only (prefer specific exceptions)

## 🎯 Constitution Principles Checked

The script validates against 7 core principles from the PostgreSQL Programming Constitution:

1. **I. ANSI-SQL Primacy** - Standard SQL over vendor extensions
2. **II. Strict Typing & Explicit Casting** - Use CAST() or ::
3. **III. Set-Based Execution** - No cursors/WHILE loops, use CTEs
4. **IV. Atomic Transaction Management** - Explicit BEGIN/COMMIT/ROLLBACK
5. **V. Idiomatic Naming & Scoping** - snake_case, schema-qualified references
6. **VI. Structured Error Resilience** - Specific exception types
7. **VII. Modular Logic Separation** - Clean schema architecture

## 🔧 Advanced Usage

### Custom File Paths
```bash
python3 scripts/automation/analyze-object.py function mcgetupstream \
  --original /path/to/original.sql \
  --converted /path/to/converted.sql \
  --output /path/to/custom-report.md
```

### Specify Project Root
```bash
# If running from different directory
python3 scripts/automation/analyze-object.py procedure AddArc \
  --project-root /Users/pierre/sqlserver-to-postgresql-migration
```

## 📈 Performance Expectations

| Operation | Time | Throughput |
|-----------|------|------------|
| Single object analysis | <5 seconds | 12+ objects/minute |
| Batch (15 objects) | <2 minutes | 7-8 objects/minute |
| Report generation | Instant | N/A |

**Tested on:** MacBook Pro M1, 16GB RAM, Python 3.11

## 🚨 Troubleshooting

### File Not Found
```
Error: Original file not found for: AddArc
```

**Solution:** Script searches recursively. Verify file exists:
```bash
find source/original/sqlserver -name "*AddArc*"
```

### Invalid Arguments
```
Error: object_type and object_name required (or use --batch)
```

**Solution:** Provide both arguments:
```bash
python3 scripts/automation/analyze-object.py procedure AddArc
```

### Batch File Format Error
```
Skipping invalid line: procedure AddArc
```

**Solution:** Use comma separator in batch file:
```txt
procedure,AddArc  ✅
procedure AddArc  ❌
```

## 📚 Exit Codes

| Code | Meaning | Example |
|------|---------|---------|
| 0 | Success | Analysis completed successfully |
| 1 | Analysis failed | File not found, parsing error |
| 2 | Invalid arguments | Missing required arguments |

Use in scripts:
```bash
if python3 scripts/automation/analyze-object.py procedure AddArc; then
  echo "Analysis succeeded"
else
  echo "Analysis failed with code: $?"
fi
```

## 💡 Tips & Best Practices

### 1. Analyze AWS SCT Output First
Always analyze the AWS SCT converted files before manual corrections:
```bash
python3 scripts/automation/analyze-object.py procedure MyProc
# Review issues, then manually correct
```

### 2. Use Batch Mode for Sprints
Create a sprint batch file with all objects for the sprint:
```bash
# sprint-3-objects.txt
procedure,proc1
procedure,proc2
function,func1
```

### 3. Track Quality Scores Over Time
```bash
# Log scores for trend analysis
echo "$(date),AddArc,$(python3 scripts/automation/analyze-object.py procedure AddArc --score-only)" >> quality-log.csv
```

### 4. Focus on High-Impact Issues First
1. Fix all P0 issues (blocks deployment)
2. Fix all P1 issues (must fix before PROD)
3. Address P2/P3 issues as time permits

## 🎓 Learning Resources

- **Constitution:** `docs/POSTGRESQL-PROGRAMMING-CONSTITUTION.md`
- **Full README:** `scripts/automation/README.md`
- **Project Spec:** `specs/001-tsql-to-pgsql/spec.md`
- **Templates:** `templates/analysis-template.md`

---

**Created:** 2026-01-25
**Version:** 1.0
**Author:** Pierre Ribeiro (DBA/DBRE)
