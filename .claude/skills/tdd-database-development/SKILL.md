---
name: tdd-database-development
description: >
  Engine-agnostic Test-Driven Development methodology for database development.
  Use whenever a sub-agent is assigned a Red, Green, or Refactor role to test or
  implement any database object — tables, columns, constraints, primary/foreign keys,
  indexes, views, materialized views, sequences, functions, procedures, triggers,
  packages, RLS policies, schemas, or migrations — in any RDBMS (PostgreSQL, Oracle,
  SQL Server, MySQL, MariaDB, SQLite, BigQuery, Snowflake, DuckDB, etc.). Trigger on
  TDD for database, Red-Green-Refactor for SQL, failing test for a table/function/
  procedure/trigger/view/constraint, AAA pattern for SQL, database TDD sub-agent, or
  test-first database development. Trigger on implicit intent too — "write a failing
  test for this procedure", "implement this trigger using TDD", "refactor this view,
  keep tests green". Defines the WORKFLOW and ROLES only; does NOT prescribe a test
  framework — the sub-agent identifies the engine and loads the engine-specific skill
  (e.g., pgtap-tdd-testing for PostgreSQL).
---

# TDD for Database Development — Agnostic Workflow

This skill teaches a sub-agent the **role it plays** inside a strict Red-Green-Refactor
(RGR) cycle for database development. It is engine-agnostic, framework-agnostic, and
language-agnostic. Production code samples in references are pseudo-code on purpose.

The skill assumes a **multi-agent architecture** with three isolated sub-agents — one per
RGR phase — coordinated by a parent skill or orchestrator. Each sub-agent loads only the
files relevant to its role.

> **Out of scope**: This skill does **NOT** instrument tests with a specific framework or
> tool. After loading this skill, the sub-agent must identify the database engine in use
> and locate the engine-specific TDD skill (e.g., `pgtap-tdd-testing` for PostgreSQL,
> `tsqlt-tdd-testing` for SQL Server, `utplsql-tdd-testing` for Oracle). See
> `references/engine-skill-discovery.md`.

---

## Architecture: Lazy Loading (Progressive Disclosure)

SKILL.md is the **router**. It contains the role detection logic, the phase gates, the
mandatory plan/report protocol, and a decision tree that points each sub-agent to the
specific reference file it needs. Detailed content lives in references loaded **only when
the role demands it**.

### Reference files — read ONLY when your role requires them

| File | Read this when… | Contains |
|------|-----------------|----------|
| `references/tdd-principles.md` | You need to remind yourself of the methodology | Three Laws of TDD, RGR cycle, baby steps, YAGNI/KISS, FIRST, emergent design |
| `references/role-red-test-writer.md` | You are assigned the **RED** role | Mandate, inputs/outputs, step-by-step process, hard rules, stop conditions |
| `references/role-green-implementer.md` | You are assigned the **GREEN** role | Mandate, inputs/outputs, "minimum code" discipline, anti-overengineering rules |
| `references/role-refactor-refactorer.md` | You are assigned the **REFACTOR** role | Mandate, decision criteria for refactoring vs. skipping, safety rules |
| `references/aaa-pattern-database.md` | Writing or reviewing a test (any role) | Arrange-Act-Assert applied to schemas, DML, procedures, triggers, RLS — pseudo-code only |
| `references/database-patterns.md` | Designing test cases or implementation | Programmatic patterns to enforce: PK/FK, normalization, atomicity, idempotency, declarative constraints |
| `references/database-anti-patterns.md` | Reviewing schema/query design before implementing | 20+ DB anti-patterns (CSV column, EAV, god table, polymorphic FK, adjacency-list-only, index shotgun, etc.) — DO NOT write tests that bake these in |
| `references/plan-and-report-protocol.md` | Starting any role, or finishing it | Mandatory plan-before-write rule, report format, update-on-repeat semantics |
| `references/engine-skill-discovery.md` | Before you write any engine-specific code | How to identify the DB engine and find/load the engine-specific TDD skill |

### Asset files — copy and fill in

| File | Purpose |
|------|---------|
| `assets/templates/role-plan-template.md` | Mandatory plan each sub-agent writes BEFORE acting |
| `assets/templates/role-report-template.md` | Mandatory report each sub-agent writes/updates AFTER acting |
| `assets/templates/red-pseudo-code.md` | Pseudo-code skeleton for a failing database test |
| `assets/templates/green-pseudo-code.md` | Pseudo-code skeleton for minimum production code |
| `assets/templates/refactor-checklist.md` | Decision aid for the Refactorer |

**Loading rule**: Read SKILL.md first. Then read ONLY the role file matching your
assignment, plus any references the role file points you to. Never load all references at
once. Skip a reference if you have already followed its rules in this same context.

---

## The RGR Cycle for Database Development

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   🔴 RED ────────► 🟢 GREEN ────────► 🔵 REFACTOR ──┐            │
│   Test Writer      Implementer        Refactorer    │            │
│   (Sub-agent A)    (Sub-agent B)      (Sub-agent C) │            │
│                                                     │            │
│         ▲                                           │            │
│         │                                           ▼            │
│         └─────────── next behavior ◄────────────────┘            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

Each sub-agent runs in **isolated context** — it does not see the others' working memory.
This prevents the *context pollution* problem where the test writer subconsciously designs
tests around an implementation it has already started planning. (See Opalic / TDAD findings
in `references/tdd-principles.md`.)

### Phase gates — strict, no skipping

1. **🔴 RED — Test Writer (Sub-agent A)**
   - Writes ONE failing test for ONE behavior of a database object.
   - Runs the test. **Confirms it fails for the right reason** (object missing, behavior
     missing — *not* a typo or a connection error).
   - Returns: test artifact location + failure output + brief summary.
   - **Phase gate**: orchestrator must NOT advance to GREEN until red failure is confirmed.

2. **🟢 GREEN — Implementer (Sub-agent B)**
   - Reads the failing test. Writes the **minimum** production code to pass it.
   - Runs the full test suite, not just the new test.
   - Returns: artifact(s) modified + green output + 1-line implementation summary.
   - **Phase gate**: orchestrator must NOT advance to REFACTOR until all tests pass.

3. **🔵 REFACTOR — Refactorer (Sub-agent C)**
   - Reads implementation + tests. Evaluates against the refactor checklist.
   - Either applies improvements (re-running tests after each change) or returns
     "no refactoring needed" with reasoning.
   - **Phase gate**: cycle ends only when refactor returns and all tests stay green.

After REFACTOR returns, the orchestrator either picks up the next behavior (back to RED)
or completes the feature.

---

## What every sub-agent must do, in order

Each sub-agent — regardless of role — follows the same five-step contract:

1. **Identify your role** from the orchestrator prompt: RED, GREEN, or REFACTOR.
2. **Read your role file** (`references/role-{red|green|refactor}-*.md`) and any
   references it points to.
3. **Identify the database engine** (PostgreSQL, Oracle, SQL Server, MySQL, BigQuery,
   etc.) and load the engine-specific TDD skill if available — see
   `references/engine-skill-discovery.md`. If no engine-specific skill is available,
   continue with pseudo-code and clearly flag this in the report.
4. **Write your plan** using `assets/templates/role-plan-template.md` BEFORE doing any
   work. The plan is short (≤ 1 page) but mandatory. See
   `references/plan-and-report-protocol.md`.
5. **Do the work**, then **write or update the report** using
   `assets/templates/role-report-template.md`. If this is a re-run of the same role on
   the same behavior, **update** the existing report — do not create a new one.

The plan-then-act-then-report contract makes the work auditable and enables fast resumption
on retry without re-deriving context.

---

## Role detection — quickly figure out which one you are

Look at the orchestrator's prompt or your invocation parameters. The role is almost always
explicit:

| Signal in prompt | Your role | Read this file |
|------------------|-----------|----------------|
| "Write a failing test for…", "RED phase", "test writer" | 🔴 RED | `references/role-red-test-writer.md` |
| "Make this test pass", "minimum code to pass", "GREEN phase", "implementer" | 🟢 GREEN | `references/role-green-implementer.md` |
| "Refactor the implementation", "REFACTOR phase", "evaluate refactoring opportunities" | 🔵 REFACTOR | `references/role-refactor-refactorer.md` |

If the role is ambiguous, **stop and ask the orchestrator** rather than guessing. A
sub-agent that picks the wrong role pollutes the cycle.

---

## The AAA pattern — every test, no exceptions

Every test the RED sub-agent writes follows **Arrange-Act-Assert**:

- **Arrange** — set up prerequisites (create test schema/table, seed rows, set session
  state, switch role for RLS, declare expected values).
- **Act** — execute the single behavior under test (run the DML, call the function/
  procedure, fire the trigger by an INSERT/UPDATE/DELETE, refresh the materialized view).
- **Assert** — verify exactly one observable outcome (row count, column value, error
  raised, side effect on another table, plan shape).

The pattern is **not** Arrange-Act-Assert-Act-Assert. A second action and assertion belong
in a separate test. Full pseudo-code examples live in `references/aaa-pattern-database.md`.

---

## Hard rules (any role can be reverted for violating these)

1. **No production code without a failing test.** If you find yourself writing a CREATE
   TABLE, CREATE FUNCTION, ALTER, INSERT, or UPDATE before a test that demands it exists
   and fails — STOP. You are not in TDD any more.
2. **One behavior per test.** If your test name contains "and", split it.
3. **Test behavior, not implementation.** Assert on observable outcomes (row contents,
   raised errors, returned values), not on internal plan choices unless the plan IS the
   behavior under test (e.g., "this query uses index X").
4. **Write directly to real files.** No temporary scratch files unless explicitly part of
   the engine-specific test harness. The orchestrator owns version control.
5. **Plan before you write. Report when you finish.** Skipping the plan or the report
   leaves the cycle un-resumable on retry.
6. **Do not bake known anti-patterns into tests.** If the spec under test perpetuates an
   anti-pattern from `references/database-anti-patterns.md`, flag it in your plan and ask
   the orchestrator before continuing.
7. **One failing test at a time.** Never write two failing tests in the same RED phase.
8. **Engine identification first.** Before writing any engine-specific syntax, determine
   the engine and load the matching skill. Pseudo-code only is acceptable as a fallback if
   no engine-specific skill exists, but flag that in the report.

---

## Decision tree — what to load right now

```
Are you a sub-agent invoked for a DB TDD task?
│
├─ Need methodology refresher? ───────────────► references/tdd-principles.md
│
├─ Role = RED?  ──────────────────────────────► references/role-red-test-writer.md
│                                                  └─► references/aaa-pattern-database.md
│                                                  └─► references/database-anti-patterns.md
│                                                  └─► assets/templates/red-pseudo-code.md
│
├─ Role = GREEN? ─────────────────────────────► references/role-green-implementer.md
│                                                  └─► references/database-patterns.md
│                                                  └─► assets/templates/green-pseudo-code.md
│
├─ Role = REFACTOR? ──────────────────────────► references/role-refactor-refactorer.md
│                                                  └─► references/database-patterns.md
│                                                  └─► assets/templates/refactor-checklist.md
│
├─ Need to know the engine? ──────────────────► references/engine-skill-discovery.md
│
└─ About to start or finish work? ────────────► references/plan-and-report-protocol.md
                                                  └─► assets/templates/role-plan-template.md
                                                  └─► assets/templates/role-report-template.md
```

---

## Quick reference: the five-line distillation

```
RED      → write ONE failing test for ONE behavior, prove it fails for the right reason
GREEN    → write the MINIMUM code to pass that one test, run the FULL suite
REFACTOR → evaluate; clean while green or return "no refactor needed"
PLAN     → before each role, fill assets/templates/role-plan-template.md
REPORT   → after each role, write/update assets/templates/role-report-template.md
```

Source of truth for the methodology: Beck (TDD by Example), Robert C. Martin (Three Laws),
Fowler (Refactor discipline), Opalic (sub-agent isolation), Alonso & Yovine (TDAD —
context beats procedure for AI agents). See `references/tdd-principles.md` for the
condensed reference.
