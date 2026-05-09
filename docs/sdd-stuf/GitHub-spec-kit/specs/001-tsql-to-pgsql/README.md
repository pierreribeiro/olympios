# Feature 001: T-SQL to PostgreSQL Migration

## Purpose

Complete specification for migrating 769 database objects from SQL Server 2014 (T-SQL) to PostgreSQL 17+ (PL/pgSQL). Covers scope, requirements, data model, implementation plan, task breakdown, and validation contracts.

## Structure

```
001-tsql-to-pgsql/
├── spec.md                         # Feature specification (23 KB)
├── data-model.md                   # Data model and schema design (20 KB)
├── plan.md                         # Implementation plan (19 KB)
├── tasks.md                        # Task breakdown - 317 tasks (47 KB)
├── quickstart.md                   # Quick start guide (18 KB)
├── research.md                     # Technical research and decisions (17 KB)
├── contracts/                      # Validation contracts
│   ├── validation-contracts.md    # Quality gates and acceptance criteria
│   └── migration-workflow-api.md  # Workflow API definitions
├── checklists/                     # Quality assurance checklists
│   ├── requirements.md            # Requirements checklist
│   └── migration-thorough-gate.md # Thoroughness gate checklist
└── backup-*.md                     # Backup versions of key artifacts
```

## Contents

### Core Specification Documents

- **[spec.md](spec.md)** (23 KB) - Feature specification covering:
  - Project scope (769 objects: procedures, functions, views, tables, indexes, constraints, types, FDW, jobs)
  - Requirements and constraints
  - Success criteria (zero production bugs, ≤20% performance variance, 100% data integrity)
  - Dependencies and risk analysis
  - Quality framework (5 dimensions)

- **[data-model.md](data-model.md)** (20 KB) - Data architecture documentation:
  - Complete object inventory (769 objects mapped)
  - Schema definitions (perseus, hermes, sqlapps, deimeter)
  - Dependency graph and relationships
  - P0 critical path (9 objects)
  - Migration patterns (TVFs, materialized views, GooList type)

- **[plan.md](plan.md)** (19 KB) - Implementation strategy:
  - 4-phase workflow (Analysis → Correction → Validation → Deployment)
  - Object-specific workflows (procedures, functions, views, tables, UDTs, FDW)
  - Resource allocation and timeline
  - Quality gates (DEV, STAGING, PROD)
  - Risk mitigation strategies

- **[tasks.md](tasks.md)** (47 KB) - **317 granular tasks** with:
  - Dependency-ordered task list
  - Time estimates (Analysis: 1-2h, Correction: 2-3h per object)
  - Priority classifications (P0-P3)
  - Assignee tracking
  - Status tracking (15/317 complete - 5%)

### Support Documents

- **[quickstart.md](quickstart.md)** (18 KB) - Quick start guide for new team members or AI assistants joining the project. Covers environment setup, key workflows, and first steps.

- **[research.md](research.md)** (17 KB) - Technical research notes documenting key decisions:
  - AWS SCT limitations and workarounds
  - PostgreSQL 17+ feature adoption
  - Materialized view refresh strategies
  - GooList type conversion patterns
  - FDW performance optimization

### Validation Artifacts

**[contracts/](contracts/)** - Validation contracts defining quality gates:
- `validation-contracts.md` - Acceptance criteria, quality gates, performance benchmarks, data integrity checks
- `migration-workflow-api.md` - Workflow API definitions for automation

**[checklists/](checklists/)** - Quality assurance checklists:
- `requirements.md` - Requirements completeness checklist
- `migration-thorough-gate.md` - Thoroughness validation checklist

### Backup Artifacts

Backup versions of key documents preserving previous states:
- `backup-spec.md` - Previous specification version
- `backup-data-model.md` - Previous data model version
- `backup-plan.md` - Previous plan version
- `backup-quickstart.md` - Previous quickstart version
- `backup-research.md` - Previous research version
- `backup-validation-contracts.md` - Previous contracts version

## Key Metrics

### Scope Summary

| Object Type | Count | Status |
|-------------|-------|--------|
| **Stored Procedures** | 21 | 15 complete (71%) |
| **Functions** | 25 | 0 complete |
| **Views** | 22 | 0 complete |
| **Tables** | 91 | 0 complete |
| **Indexes** | 352 | 0 complete |
| **Constraints** | 271 | 0 complete |
| **UDT (GooList)** | 1 | 0 complete |
| **FDW Connections** | 3 | 0 complete |
| **SQL Agent Jobs** | 7 | 0 complete |
| **TOTAL** | **769** | **15 complete (2%)** |

### Task Breakdown

**317 tasks total:**
- Procedures: 105 tasks (15 complete)
- Functions: 75 tasks
- Views: 66 tasks
- Tables: 45 tasks
- Infrastructure: 26 tasks

**Time estimates:**
- Analysis: 1-2 hours per object
- Correction: 2-3 hours per object
- Validation: 1 hour per object
- Total per object: 4-6 hours (with pattern reuse: 3-5 hours)

### Quality Targets

**Minimum thresholds:**
- Quality score: ≥7.0/10 overall, NO dimension below 6.0/10
- Performance: Within ±20% of SQL Server baseline
- Zero P0/P1 issues before STAGING
- 100% data integrity validation

**Achieved in Sprint 3:**
- Average quality: 8.67/10 ✅
- Performance: +63% to +97% improvement ✅
- Zero P0/P1 issues ✅

## Usage Guide

### For New Team Members

1. **Start with**: [quickstart.md](quickstart.md) - Get oriented quickly
2. **Read**: [spec.md](spec.md) - Understand full scope and requirements
3. **Review**: [data-model.md](data-model.md) - Learn object relationships
4. **Study**: [plan.md](plan.md) - Understand workflow and quality gates
5. **Execute**: Follow [tasks.md](tasks.md) - Work through prioritized tasks

### For AI Assistants (Claude Code)

1. **Context**: Read [spec.md](spec.md) + [data-model.md](data-model.md) for project understanding
2. **Workflow**: Follow 4-phase process in [plan.md](plan.md)
3. **Tasks**: Use [tasks.md](tasks.md) for granular execution tracking
4. **Validation**: Apply contracts from [contracts/validation-contracts.md](contracts/validation-contracts.md)
5. **Quality**: Reference checklists in [checklists/](checklists/)

### For Project Management

1. **Progress tracking**: Monitor [tasks.md](tasks.md) status column
2. **Risk assessment**: Review blockers and dependencies in [tasks.md](tasks.md)
3. **Quality metrics**: Track against contracts in [contracts/](contracts/)
4. **Timeline updates**: Update estimates in [plan.md](plan.md) based on actuals

## Document Update Workflow

### When to Update

**spec.md** - Update when:
- Requirements change
- Scope adjustments
- New constraints identified

**data-model.md** - Update when:
- New dependencies discovered
- Schema changes
- Object count corrections

**plan.md** - Update when:
- Workflow changes
- Timeline adjustments
- Resource allocation changes

**tasks.md** - Update when:
- Tasks completed (mark status)
- New tasks identified
- Time estimates refined
- Dependencies change

**research.md** - Update when:
- New technical decisions made
- Patterns discovered
- Workarounds found

### Version Control

**Before major updates:**
1. Copy current version to `backup-<filename>.md`
2. Make changes to active version
3. Document changes in commit message
4. Keep backups for reference

## Next Steps

**Current Phase:** Phase 2 - P0 Critical Path

**Immediate priorities** (from [tasks.md](tasks.md)):
1. **VIEW** `translated` - Materialized view conversion (Task #106)
2. **TYPE** `GooList` - TEMPORARY TABLE pattern (Task #205)
3. **FUNCTIONS** McGet* family - 4 functions (Tasks #138-141)
4. **TABLES** Foundation - 3 tables (Tasks #160, #165, #170)

**Track progress in:**
- [tasks.md](tasks.md) - Task status
- `/tracking/progress-tracker.md` - Sprint dashboard
- `/tracking/activity-log-2026-01.md` - Session logs

## Navigation

- See [contracts/](contracts/) for validation criteria
- See [checklists/](checklists/) for quality assurance
- Up: [../README.md](../README.md)
- Project root: [../../README.md](../../README.md)

---

**Last Updated:** 2026-01-22 | **Feature Status:** In Progress (15/769 objects, 2%) | **Next Milestone:** P0 Critical Path (9 objects)
