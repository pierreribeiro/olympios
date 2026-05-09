# Validation Scripts

## 📁 Directory Purpose

This directory contains **automated validation scripts** to verify PostgreSQL procedure quality, syntax, performance, and correctness before deployment.

**Key Functions:**
- ✅ Syntax validation (PostgreSQL parser)
- ✅ Dependency checking (missing objects)
- ✅ Data integrity verification
- ✅ Performance benchmarking
- ✅ Quality scoring

---

## 🎯 Validation Philosophy

**Automate Everything That Can Be Automated**

Manual review is expensive and error-prone. These scripts provide:
- Fast feedback (seconds vs. minutes)
- Consistent checks (no human variability)
- Repeatable results (CI/CD friendly)
- Comprehensive coverage (catch edge cases)

---

## 📋 Available Scripts

### 1. syntax-check.sh
**Purpose:** Validate PostgreSQL syntax without executing code

**Usage:**
```bash
./scripts/validation/syntax-check.sh <procedure_file.sql>
```

**What It Does:**
- Parses SQL with `psql --dry-run` or `pg_syntax_check`
- Identifies syntax errors
- Reports line numbers and error details
- Returns exit code (0=pass, 1=fail)

**Example:**
```bash
./scripts/validation/syntax-check.sh procedures/corrected/reconcilemupstream.sql

✅ PASS - No syntax errors detected
```

**When To Use:**
- Before committing to git
- In CI/CD pipeline
- After manual code changes
- Before deployment

---

### 2. dependency-check.sql
**Purpose:** Verify all dependent objects exist

**Usage:**
```bash
psql -h localhost -d perseus_dev -f scripts/validation/dependency-check.sql
```

**What It Checks:**
- Referenced tables exist
- Referenced columns exist
- Called procedures/functions exist
- Required permissions granted
- Schema objects present

**Example Output:**
```
CHECKING DEPENDENCIES FOR: reconcilemupstream
✅ Table: M_Upstream - EXISTS
✅ Table: M_Downstream - EXISTS  
✅ Function: GetMaterialID - EXISTS
❌ Table: AuditLog - MISSING
⚠️  WARNING: Missing dependency detected
```

**When To Use:**
- Before first deployment to new environment
- After schema changes
- When debugging "object not found" errors
- As part of smoke test

---

### 3. data-integrity-check.sql
**Purpose:** Verify procedure doesn't corrupt data

**Usage:**
```bash
psql -h localhost -d perseus_dev -f scripts/validation/data-integrity-check.sql
```

**What It Does:**
- Takes snapshot of key tables (before)
- Executes procedure with test data
- Takes snapshot of key tables (after)
- Compares snapshots
- Verifies constraints not violated
- Checks referential integrity

**Example Tests:**
```sql
-- Verify row counts match expectations
SELECT COUNT(*) FROM M_Upstream;  -- Before: 1000
CALL reconcilemupstream(...);
SELECT COUNT(*) FROM M_Upstream;  -- After: 1000 (no orphans)

-- Verify foreign keys intact
SELECT COUNT(*) FROM M_Upstream WHERE MaterialID NOT IN (SELECT ID FROM Materials);
-- Expected: 0

-- Verify unique constraints
SELECT MaterialID, COUNT(*) FROM M_Upstream GROUP BY MaterialID HAVING COUNT(*) > 1;
-- Expected: 0 rows
```

**When To Use:**
- After corrections applied
- Before deployment to QA
- After any data model changes
- When investigating data corruption

---

### 4. performance-test.sql
**Purpose:** Benchmark procedure performance

**Usage:**
```bash
psql -h localhost -d perseus_dev -f scripts/validation/performance-test.sql
```

**What It Measures:**
- Execution time (wall clock)
- Rows processed per second
- Buffer cache hits
- Disk I/O
- Lock contention
- Memory usage

**Example:**
```sql
-- Benchmark with EXPLAIN ANALYZE
EXPLAIN (ANALYZE, BUFFERS, VERBOSE) 
SELECT * FROM reconcilemupstream(param1, param2);

-- Results:
-- Execution Time: 1250.45 ms (SQL Server: 980.23 ms)
-- Delta: +27.5% (FAIL - exceeds 20% threshold)
-- Shared Buffers Hit: 95.2%
-- Rows Processed: 10,000
-- Throughput: 8,000 rows/sec
```

**Performance Targets:**
- Execution time: ≤120% of SQL Server baseline
- Buffer hit ratio: ≥90%
- No full table scans (unless intended)
- No lock timeouts

**When To Use:**
- After every correction
- Before deployment to QA
- When investigating slow queries
- For capacity planning

---

## 🔧 Configuration Files

### validation-config.json
Stores validation parameters:
```json
{
  "syntax_check": {
    "postgresql_version": "16",
    "strict_mode": true,
    "warnings_as_errors": false
  },
  "performance_test": {
    "max_execution_time_ms": 5000,
    "sql_server_baseline_ms": 980,
    "max_delta_percent": 20,
    "min_buffer_hit_ratio": 0.90
  },
  "dependency_check": {
    "fail_on_missing": true,
    "check_permissions": true
  }
}
```

---

## 🎯 Quality Gates

Procedures must pass ALL validations to advance:

| Gate | Script | Pass Criteria | Blocking? |
|------|--------|---------------|-----------|
| **Syntax** | syntax-check.sh | 0 errors | ✅ YES |
| **Dependencies** | dependency-check.sql | All objects exist | ✅ YES |
| **Data Integrity** | data-integrity-check.sql | No corruption | ✅ YES |
| **Performance** | performance-test.sql | ≤120% of baseline | ⚠️ WARNING |

**Blocking gates MUST pass before deployment**

---

## 🚀 CI/CD Integration

### GitHub Actions Example
```yaml
name: Validate Procedures

on:
  push:
    paths:
      - 'procedures/corrected/*.sql'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup PostgreSQL
        uses: ikalnytskyi/action-setup-postgres@v4
        
      - name: Syntax Check
        run: |
          for file in procedures/corrected/*.sql; do
            ./scripts/validation/syntax-check.sh "$file"
          done
          
      - name: Dependency Check
        run: |
          psql -f scripts/validation/dependency-check.sql
          
      - name: Data Integrity Check
        run: |
          psql -f scripts/validation/data-integrity-check.sql
          
      - name: Performance Test
        run: |
          psql -f scripts/validation/performance-test.sql
```

---

## 📊 Validation Report Example

```
===========================================
VALIDATION REPORT: reconcilemupstream.sql
===========================================

1. SYNTAX CHECK ✅
   Status: PASS
   Errors: 0
   Warnings: 2 (minor style issues)

2. DEPENDENCY CHECK ✅
   Status: PASS
   Tables: 5/5 found
   Functions: 2/2 found
   Permissions: GRANTED

3. DATA INTEGRITY ✅
   Status: PASS
   Rows affected: 10,000
   Orphaned records: 0
   Constraint violations: 0
   FK integrity: OK

4. PERFORMANCE ⚠️
   Status: WARNING
   Execution time: 1,250 ms (baseline: 980 ms)
   Delta: +27.5% (exceeds +20% threshold)
   Buffer hit: 95.2%
   Recommendation: Add index on MaterialID

===========================================
OVERALL: ⚠️ PASS WITH WARNINGS
Deployment: APPROVED for DEV
            REQUIRES optimization for QA
===========================================
```

---

## 🛠️ Creating New Validation Scripts

**Template:**
```bash
#!/bin/bash
# scripts/validation/my-new-check.sh
# Description: [What this validates]
# Usage: ./my-new-check.sh <procedure_file>

set -euo pipefail

PROCEDURE_FILE="${1:?Missing procedure file}"

# 1. Setup (temp tables, connections, etc.)

# 2. Run validation logic

# 3. Report results

# 4. Cleanup

# 5. Exit with code (0=pass, 1=fail)
```

---

## 📚 Related Documentation

- Validation results: `/tracking/validation-results.md`
- Test data: `/tests/fixtures/`
- Deployment scripts: `/scripts/deployment/`
- Project plan: `/docs/PROJECT-PLAN.md`
- Quality standards: `/docs/quality-standards.md`

---

## 🚨 Troubleshooting

### Syntax Check Fails But psql Works
```bash
# Try with actual PostgreSQL parser
psql -h localhost -d postgres -c "\i procedure.sql"
```

### Dependency Check False Positives
```sql
-- Verify search_path
SHOW search_path;

-- Check schema qualification
\dt schema.*
```

### Performance Test Variability
```bash
# Run multiple times and average
for i in {1..5}; do
  psql -f performance-test.sql
done | awk '{sum+=$1} END {print sum/NR}'
```

---

**Maintained by:** Pierre Ribeiro (DBA/DBRE)  
**Last Updated:** 2025-11-13  
**Version:** 1.0
