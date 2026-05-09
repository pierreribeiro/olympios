# Workflow Guide: User Story Execution

**Project**: Perseus Database Migration (SQL Server → PostgreSQL 17)
**Context**: This guide defines **mandatory** execution practices for all User Stories in `tasks.md`
**Authority**: These practices are **REQUIRED** for all Claude Code agents working on this project

---

## ⚠️ **IMPORTANT: Autonomous Execution by Claude Code**

**WHO EXECUTES**: All commands and workflows in this guide are executed **autonomously by Claude Code agents**, not manually by the user.

**AVAILABLE TOOLS**:
- ✅ **Local Git Commands**: Claude Code has direct access to execute `git`, `gh` CLI commands
- ✅ **MCP GitHub Tools**: Claude Code can use `mcp__github-official-tools` for PR/issue management
- ✅ **File Operations**: Claude Code can read, write, edit files directly
- ✅ **Shell Execution**: Claude Code can run bash commands, scripts, validation tools

**EXECUTION MODEL**:
- When this guide says "Create worktree", Claude Code executes `git worktree add` directly
- When this guide says "Push to remote", Claude Code executes `git push` directly
- When this guide says "Create PR", Claude Code executes `gh pr create` or MCP tools directly
- User provides high-level direction ("Start User Story 1"), Claude Code executes all steps autonomously

**USER ROLE**: The user provides strategic direction and approvals; Claude Code handles all tactical execution.

---

## 🎯 **Core Principles**

1. **Parallel Execution**: Maximize throughput by running independent tasks concurrently
2. **Worktree Isolation**: Each User Story works in its own git worktree to avoid conflicts
3. **Tool Discipline**: Mandatory use of Database Agents, Skills, and Ralph Loop Plugin
4. **Branch Strategy**: `001-tsql-to-pgsql` is the parent branch for all User Story worktrees
5. **Progress Tracking**: Real-time updates in `tracking/progress-tracker.md`

---

## 📁 **Worktree Strategy**

### **Directory Structure**

```
~/.claude-worktrees/
├── US1-critical-views/          # User Story 1 worktree
├── US2-table-valued-functions/  # User Story 2 worktree
├── US3-core-tables/              # User Story 3 worktree
├── US4-indexes-constraints/      # User Story 4 worktree
└── US5-stored-procedures/        # User Story 5 worktree (COMPLETED - can be removed)
```

### **Naming Convention**

**Format**: `US{number}-{descriptive-slug}`

**Examples**:
- `US1-critical-views`
- `US2-table-valued-functions`
- `US3-core-tables`
- `US4-indexes-constraints`
- `US6-fdw-integration`

**Rules**:
- Lowercase with hyphens
- Max 40 characters
- Descriptive enough to identify User Story at a glance

---

## 🌳 **Worktree Setup (Step-by-Step)**

**NOTE**: These steps are executed **autonomously by Claude Code** when starting a User Story. Commands shown are for reference and understanding of the workflow.

---

### **Before Starting a User Story**

1. **Verify Parent Branch is Clean** (Claude Code executes)
   ```bash
   cd /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration
   git checkout 001-tsql-to-pgsql
   git pull origin 001-tsql-to-pgsql
   git status  # Should show "working tree clean"
   ```

2. **Create Worktree** (Claude Code executes)
   ```bash
   # For User Story 1
   git worktree add ~/.claude-worktrees/US1-critical-views -b us1-critical-views 001-tsql-to-pgsql

   # Navigate to worktree
   cd ~/.claude-worktrees/US1-critical-views
   ```

3. **Verify Worktree Setup** (Claude Code executes)
   ```bash
   git branch  # Should show: * us1-critical-views
   git log --oneline -3  # Should match 001-tsql-to-pgsql
   ```

4. **Open Worktree in Claude Code** (Claude Code executes)
   ```bash
   # From worktree directory
   claude .
   # OR specify path
   claude ~/.claude-worktrees/US1-critical-views
   ```

---

## 🤖 **Mandatory Tools & Agents**

### **Database Agents (REQUIRED - Use Proactively)**

**Priority Order** (per CLAUDE.md):

1. **`database-expert`** ⭐⭐⭐⭐⭐ (PRIMARY)
   - **Use for**: ALL SQL analysis, dependency review, query optimization, schema design
   - **Tasks**: T031-T038 (analysis), T047-T091 (validation), T118+ (integration)
   - **When**: Start EVERY analysis/refactoring/validation task with this agent

2. **`sql-pro`** ⭐⭐⭐⭐⭐ (CO-PRIMARY)
   - **Use for**: Complex SQL refactoring, CTEs, window functions, query rewriting
   - **Tasks**: T040-T073 (refactoring), T179-T183 (optimization)
   - **When**: Converting T-SQL to PostgreSQL, optimizing queries

3. **`database-optimization`** ⭐⭐⭐⭐
   - **Use for**: Performance ±20% validation, EXPLAIN ANALYZE, index strategy
   - **Tasks**: T052, T118, T179-T183, T220-T222
   - **When**: Performance testing, query plan analysis

4. **`systematic-debugging`** ⭐⭐⭐⭐
   - **Use for**: P0/P1 bugs, test failures, syntax errors, logic issues
   - **Tasks**: Any task that encounters errors or test failures
   - **When**: BEFORE proposing fixes for bugs

### **Skills (RECOMMENDED - Use Proactively)**

- **`test-driven-development`**: Use BEFORE implementing T047-T091 (test creation)
- **`code-reviewer`**: Use AFTER completing refactoring tasks (self-review)
- **`senior-backend`**: Use for complex transaction/error handling decisions

### **Ralph Loop Plugin (MANDATORY for Batch Tasks)**

**Activate When**:
- Batch conversions: 10+ similar objects (views, functions, tables)
- Iterative workflows: analyze → fix → validate → repeat
- Pattern-based migrations: same transformation × N objects

**Example Tasks**:
- T034-T038: Analyze 22 views (batch analysis)
- T040-T045: Refactor 22 views (batch refactoring)
- T047-T050: Create unit tests for 22 views (batch test generation)

**Usage**:
```bash
/ralph-loop

Task: Analyze 22 views from User Story 1 (per dependency-analysis-lote3-views.md)
Order: P3 (simple views) → P2 → P1 → P0 (translated materialized view last)
Iterate: Read AWS SCT → Apply constitution → Schema-qualify → Validate syntax
Checkpoint: After every 5 views, commit with quality scores
Gate: Before P0 translated view, validate ALL 21 view dependencies
Exit: All 22 views analyzed + quality scores ≥7.0/10
```

---

## ⚡ **Parallel Execution Strategy**

### **Identifying Parallel Tasks**

Tasks marked with `[P]` in tasks.md can run in parallel:
- Different files (no file-level conflicts)
- No logical dependencies (can execute independently)

**Example from User Story 1**:
```markdown
- [ ] T034 [P] [US1] Analyze `translated` view → can run in parallel
- [ ] T035 [P] [US1] Analyze `upstream` view  → can run in parallel
- [ ] T036 [P] [US1] Analyze `downstream` view → can run in parallel
- [ ] T039 [US1] Consolidate findings → MUST run AFTER T034-T038
```

### **Running Tasks in Parallel**

**Option 1: Multiple Agents in Same Session** (via Task tool) (PREFERABLE)
```markdown
User: "Launch 3 agents in parallel to analyze T034, T035, T036"

Claude sends single message with 3 Task tool calls:
- Task 1: database-expert analyzing translated view
- Task 2: database-expert analyzing upstream view
- Task 3: database-expert analyzing downstream view
```

**Option 2: Multiple Claude Code Sessions** 
```bash
# Terminal 1 - Main worktree
cd ~/.claude-worktrees/US1-critical-views
claude .
# Work on T034

# Terminal 2 - Same worktree, different task
cd ~/.claude-worktrees/US1-critical-views
claude .
# Work on T035 (different file)

# Terminal 3 - Same worktree, different task
cd ~/.claude-worktrees/US1-critical-views
claude .
# Work on T036 (different file)
```

### **Parallelization Rules**

✅ **CAN run in parallel**:
- Tasks with `[P]` marker
- Different output files
- Different database objects
- Independent analysis tasks

❌ **CANNOT run in parallel**:
- Same file (merge conflict risk)
- Sequential dependencies (T039 depends on T034-T038)
- Shared state (progress tracker updates)

---

## 📊 **Progress Tracking**

### **Update Frequency**

- **Per Task**: Mark task as complete in tasks.md when finished
- **Per Phase**: Update `tracking/progress-tracker.md` with quality scores
- **Per Commit**: Include task IDs in commit messages

### **Commit Message Format**

```bash
# Single task
git commit -m "feat(US1): complete T034 - analyze translated view (8.5/10.0)"

# Multiple parallel tasks
git commit -m "feat(US1): complete T034-T036 - analyze 3 critical views (avg 8.7/10.0)"

# Phase completion
git commit -m "feat(US1): complete Phase 1 analysis - all 22 views analyzed (avg 8.4/10.0)"
```

### **Progress Tracker Updates**

After completing a task group, update `tracking/progress-tracker.md`:

```markdown
## User Story 1: Critical Views Migration

**Status**: Phase 1 Analysis - IN PROGRESS (18/22 views analyzed)

| Task | Object | Status | Quality Score | Issues |
|------|--------|--------|---------------|--------|
| T034 | translated | ✅ COMPLETE | 8.5/10.0 | AWS SCT used indexed view (needs materialized) |
| T035 | upstream | ✅ COMPLETE | 9.0/10.0 | Recursive CTE - minor fixes needed |
| T036 | downstream | ✅ COMPLETE | 8.8/10.0 | Recursive CTE - schema qualification |
| T037 | goo_relationship | 🔄 IN PROGRESS | - | - |
```

---

## 🔄 **Worktree Workflow (Complete Cycle)**

**NOTE**: All commands shown below are executed **autonomously by Claude Code**, not manually by the user. When the user requests "Start User Story 1", Claude Code executes these steps automatically using available git/gh tools.

---

### **1. Start User Story** (Claude Code executes)

```bash
# Create worktree
git worktree add ~/.claude-worktrees/US1-critical-views -b us1-critical-views 001-tsql-to-pgsql
cd ~/.claude-worktrees/US1-critical-views

# Open in Claude Code
claude .
```

### **2. Work on Tasks** (Claude Code executes)

```bash
# Read execution requirements in tasks.md
# Activate required agents (database-expert, sql-pro)
# Enable Ralph Loop if batch tasks
# Execute tasks (parallel where marked [P])
# Commit frequently with task IDs
git add source/building/pgsql/refactored/views/translated-analysis.md
git commit -m "feat(US1): complete T034 - analyze translated view (8.5/10.0)"
```

### **3. Merge Back to Parent** (Claude Code executes)

```bash
# Push worktree branch
git push origin us1-critical-views

# Create PR from worktree branch to parent
gh pr create --base 001-tsql-to-pgsql --head us1-critical-views \
  --title "User Story 1: Critical Views Migration - Phase 1 Analysis Complete" \
  --body "Completes T031-T039 (22 views analyzed, avg quality 8.4/10.0)"

# After PR approval, merge
gh pr merge --squash --delete-branch
```

### **4. Clean Up Worktree** (Claude Code executes)

```bash
# After merge, remove worktree
cd /Users/pierre.ribeiro/workspace/projects/amyris/sqlserver-to-postgresql-migration
git worktree remove ~/.claude-worktrees/US1-critical-views

# Verify removal
git worktree list
```

---

## 🚦 **Phase Gates & Quality Checks**

### **Before Starting a Phase**

✅ **Verify Prerequisites**:
- Previous phase complete (all tasks marked ✅)
- Parent branch `001-tsql-to-pgsql` up to date
- Required tools/scripts available (Phase 2 foundational tasks complete)

### **During Phase Execution**

✅ **Continuous Validation**:
- Syntax check: `scripts/validation/syntax-check.sh <file>`
- Dependency check: `psql -f scripts/validation/dependency-check.sql`
- Quality score: `python scripts/automation/analyze-object.py --type <type> --name <name>`

### **Before Completing a Phase**

✅ **Phase Gate Checks**:
```bash
# Run phase gate validation
psql -f scripts/validation/phase-gate-check.sql

# Check quality scores (must be ≥7.0/10.0)
# Review tracking/progress-tracker.md

# Ensure no P0/P1 issues in analysis docs
```

---

## 🎓 **Best Practices**

### **DO**

✅ Create worktree BEFORE starting User Story
✅ Use database-expert for ALL SQL-related tasks
✅ Enable Ralph Loop for batch conversions (10+ objects)
✅ Run `[P]` tasks in parallel (multiple sessions or agents)
✅ Commit frequently with task IDs and quality scores
✅ Update progress tracker after each task group
✅ Create PR from worktree branch to parent
✅ Clean up worktree after merge

### **DON'T**

❌ Work directly on `001-tsql-to-pgsql` branch
❌ Skip database agents (mandatory per CLAUDE.md)
❌ Run sequential tasks in parallel (respect dependencies)
❌ Merge without PR review
❌ Leave worktrees active after completion
❌ Forget to update tasks.md checkboxes
❌ Skip quality score validation

---

## 📖 **Quick Reference**

### **Worktree Commands**

```bash
# Create worktree
git worktree add <path> -b <branch> <parent-branch>

# List worktrees
git worktree list

# Remove worktree
git worktree remove <path>

# Navigate to worktree
cd ~/.claude-worktrees/<worktree-name>
```

### **Agent Invocation**

```bash
# Database Expert (most common)
/database-expert

# SQL Pro (refactoring)
/sql-pro

# Ralph Loop (batch tasks)
/ralph-loop
```

### **Validation Commands**

```bash
# Syntax check
./scripts/validation/syntax-check.sh source/building/pgsql/refactored/views/*.sql

# Quality analysis
python scripts/automation/analyze-object.py --type view --name translated

# Performance test
psql -f scripts/validation/performance-test-framework.sql
```

---

## 🔗 **Related Documents**

- **CLAUDE.md**: Database agent priorities and usage guidelines
- **tasks.md**: All User Stories and task definitions
- **spec.md**: Project requirements and constraints
- **plan.md**: Implementation strategy and architecture
- **tracking/progress-tracker.md**: Real-time progress updates

---

**Last Updated**: 2026-01-25
**Maintained By**: Pierre Ribeiro (Senior DBA/DBRE)
**Status**: ACTIVE - applies to all User Stories (US1-US10+)
