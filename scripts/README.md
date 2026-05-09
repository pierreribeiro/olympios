# Scripts Directory

## Purpose

Automation, validation, and deployment scripts supporting the Perseus database migration workflow. Provides tools for environment setup, analysis generation, quality validation, and deployment automation.

## Structure

```
scripts/
├── automation/      # ✅ Python scripts for analysis and test generation
├── deployment/      # 🚧 Deployment automation (planned)
└── validation/      # ✅ Environment and quality validation scripts
```

## Contents

### Automation Scripts (✅ Available)

**[automation/](automation/)** - Python-based automation tools

- `requirements.txt` - Python package dependencies (sqlparse, click, pandas, rich, jinja2, pyyaml, beautifulsoup4, lxml, tabulate)
- `automation-config.json` - Configuration file for automation scripts
- `README.md` - Detailed automation script documentation

**Planned Python Scripts** (to be implemented):
- `analyze-object.py` - Generate analysis documents for any database object type
- `compare-versions.py` - Side-by-side comparison (original, AWS SCT, corrected)
- `generate-tests.py` - Auto-generate unit test templates from procedure signatures

**Installation:**
```bash
pip install -r scripts/automation/requirements.txt
```

### Validation Scripts (✅ Available)

**[validation/](validation/)** - Environment and code quality validation

- `check-setup.sh` - Validates development environment (PostgreSQL, Python, dependencies)
- `README.md` - Validation script documentation

**Planned Validation Scripts:**
- `syntax-check.sh` - PostgreSQL syntax validation
- `dependency-check.sql` - Object dependency resolution validation
- `performance-test.sql` - Performance benchmark against SQL Server baseline
- `data-integrity-check.sql` - Row count and checksum validation

**Usage:**
```bash
./scripts/validation/check-setup.sh
```

### Deployment Scripts (🚧 Planned)

**[deployment/](deployment/)** - Deployment automation for DEV/STAGING/PROD

- `README.md` - Deployment script documentation

**Planned Deployment Scripts:**
- `deploy-object.sh` - Deploy object to target environment
- `rollback-object.sh` - Rollback object deployment
- `smoke-test.sh` - Post-deployment smoke tests

**Planned Usage:**
```bash
./scripts/deployment/deploy-object.sh <object>.sql [dev|staging|prod]
```

## Quick Reference

### Environment Setup

```bash
# Validate environment
./scripts/validation/check-setup.sh

# Install Python dependencies
pip install -r scripts/automation/requirements.txt
```

### Analysis Generation (Planned)

```bash
# Generate analysis for any object type
python scripts/automation/analyze-object.py \
  --type [procedure|function|view|table] \
  --original source/original/sqlserver/<object>.sql \
  --converted source/original/pgsql-aws-sct-converted/<object>.sql \
  --output docs/code-analysis/<type>/<object>-analysis.md
```

### Validation (Partial Implementation)

```bash
# Environment check (available)
./scripts/validation/check-setup.sh

# Syntax validation (planned)
./scripts/validation/syntax-check.sh <object>.sql

# Dependency validation (planned)
psql -d perseus_dev -f scripts/validation/dependency-check.sql

# Performance testing (planned)
psql -d perseus_dev -f scripts/validation/performance-test.sql
```

### Deployment (Planned)

```bash
# Deploy to DEV
./scripts/deployment/deploy-object.sh <object>.sql dev

# Run smoke tests
./scripts/deployment/smoke-test.sh <object_name> dev

# Deploy to STAGING (requires DEV success)
./scripts/deployment/deploy-object.sh <object>.sql staging

# Deploy to PROD (requires STAGING approval)
./scripts/deployment/deploy-object.sh <object>.sql prod
```

## Implementation Status

| Script Category | Status | Priority | Files |
|----------------|--------|----------|-------|
| **Automation** | ✅ Partial | P1 | requirements.txt, config (scripts planned) |
| **Validation** | ✅ Partial | P0 | check-setup.sh (additional scripts planned) |
| **Deployment** | 🚧 Planned | P2 | README only (scripts planned) |

## Development Guidelines

**When adding scripts:**
1. Update appropriate subdirectory README with usage examples
2. Add error handling and validation
3. Include help text (`--help` flag)
4. Test in DEV environment first
5. Document in this README

**Script conventions:**
- Bash scripts: Use `.sh` extension
- Python scripts: Use `.py` extension with shebang
- Configuration: Use `.json` or `.yaml` format
- Make scripts executable: `chmod +x script.sh`

## Navigation

- See [automation/README.md](automation/README.md) for Python automation details
- See [validation/README.md](validation/README.md) for validation script details
- See [deployment/README.md](deployment/README.md) for deployment script details
- Up: [../README.md](../README.md)

---

**Last Updated:** 2026-01-22 | **Status:** Environment validation ready, automation/deployment scripts planned
