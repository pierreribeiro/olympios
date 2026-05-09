# Specifications Directory

## Purpose

Feature specifications and design artifacts for Perseus database migration. Contains structured specifications, data models, implementation plans, task lists, and validation contracts.

## Structure

```
specs/
└── 001-tsql-to-pgsql/    # T-SQL to PostgreSQL migration specification
    ├── spec.md                    # Feature specification
    ├── data-model.md              # Data model and schema design
    ├── plan.md                    # Implementation plan
    ├── tasks.md                   # Actionable task list (317 tasks)
    ├── quickstart.md              # Quick start guide
    ├── research.md                # Research and technical decisions
    ├── contracts/                 # Validation contracts
    ├── checklists/                # Quality checklists
    └── backup-*.md                # Backup versions of key artifacts
```

## Contents

### Active Feature: 001-tsql-to-pgsql

**[001-tsql-to-pgsql/](001-tsql-to-pgsql/)** - Complete T-SQL to PostgreSQL migration specification

This is the primary active feature covering the migration of all 769 database objects from SQL Server 2014 to PostgreSQL 17+.

**Key Artifacts:**
- Feature specification (scope, requirements, constraints)
- Data model documentation (769 objects mapped)
- Implementation plan (4-phase workflow)
- Task breakdown (317 granular tasks)
- Validation contracts (quality gates, acceptance criteria)
- Research notes (technical decisions, patterns)

See [001-tsql-to-pgsql/README.md](001-tsql-to-pgsql/README.md) for detailed documentation.

## Specification Framework

### Document Structure

Each feature specification includes:

1. **spec.md** - Core specification
   - Feature overview and scope
   - Requirements and constraints
   - Success criteria
   - Dependencies
   - Risk analysis

2. **data-model.md** - Data architecture
   - Schema definitions
   - Object relationships
   - Data flow diagrams
   - Migration patterns

3. **plan.md** - Implementation strategy
   - Phase breakdown
   - Workflow definitions
   - Resource allocation
   - Timeline estimates

4. **tasks.md** - Execution details
   - Granular task list
   - Dependency ordering
   - Time estimates
   - Assignee tracking

5. **contracts/** - Validation criteria
   - Acceptance criteria
   - Quality gates
   - Performance benchmarks
   - Data integrity checks

6. **checklists/** - Quality assurance
   - Pre-implementation checklist
   - In-progress validation
   - Completion criteria

## Feature Lifecycle

### 1. Specification Phase
- Create `spec.md` with requirements
- Define data model in `data-model.md`
- Document research in `research.md`

### 2. Planning Phase
- Break down into tasks in `tasks.md`
- Create implementation plan in `plan.md`
- Define validation contracts

### 3. Execution Phase
- Track task progress in `tasks.md`
- Update plan with actuals
- Log decisions and changes

### 4. Validation Phase
- Execute validation contracts
- Complete checklists
- Document outcomes

### 5. Closure Phase
- Archive completed specs
- Extract lessons learned
- Update templates

## Current Status

### Active Features

| Feature ID | Name | Status | Tasks Complete | Last Updated |
|------------|------|--------|----------------|--------------|
| **001-tsql-to-pgsql** | Perseus Migration | 🔄 In Progress | 15/317 (5%) | 2026-01-22 |

### Completed Features

(None yet - first major feature in progress)

## Naming Convention

**Feature directories:** `NNN-feature-name/`
- NNN: 3-digit sequential ID (001, 002, etc.)
- feature-name: Kebab-case descriptive name
- Example: `001-tsql-to-pgsql`, `002-fdw-setup`, `003-materialized-views`

**Standard files:**
- `spec.md` - Feature specification
- `data-model.md` - Data architecture
- `plan.md` - Implementation plan
- `tasks.md` - Task breakdown
- `quickstart.md` - Quick start guide
- `research.md` - Technical research
- `contracts/` - Validation contracts
- `checklists/` - Quality checklists

## Navigation

- See [001-tsql-to-pgsql/README.md](001-tsql-to-pgsql/README.md) for migration specification
- Up: [../README.md](../README.md)

---

**Last Updated:** 2026-01-22 | **Active Features:** 1 (001-tsql-to-pgsql)
