---
name: pgtap-tdd-testing
description: >
  Write, organize, and run automated unit tests for PostgreSQL databases using pgTAP and
  pg_prove following Test-Driven Development (TDD) principles. Use this skill whenever the
  user mentions pgTAP, pg_prove, TAP output, database testing, PostgreSQL unit tests, test-driven
  development for databases, or asks to test PostgreSQL tables, functions, procedures, triggers,
  views, indexes, constraints, or RLS policies. Also trigger when the user asks to write a failing
  test before implementation, run pg_prove, parse TAP output, generate test skeletons, validate
  schema structure, test database behavior, or apply Red-Green-Refactor to SQL code. Trigger even
  when the user describes the intent without naming pgTAP — e.g., "write a unit test for this
  function", "I need to verify this trigger fires correctly", "test that this constraint rejects
  bad data", or "set up automated tests for my PostgreSQL schema". Assume pgTAP is already
  installed on the target database; this skill does NOT cover installation.
---

# pgTAP TDD Testing

Write, organize, and run automated unit tests for PostgreSQL using pgTAP (the `tap` extension)
and `pg_prove` (the CLI test harness), following the Red-Green-Refactor cycle of Test-Driven
Development.

This skill assumes `CREATE EXTENSION pgtap;` has already been run on the target database.
Installation is out of scope.

## Architecture: Lazy Loading (Progressive Disclosure)

This skill uses progressive disclosure to minimize token consumption. SKILL.md provides the
workflow router, the Red-Green-Refactor cycle, and the decision tree for routing to references.
Detailed content lives in reference files loaded **only when needed**.

### Reference Files — read ONLY when the task requires them

| File | Read when… | Contains |
|------|------------|----------|
| `references/object-recipes.md` | Writing a test for a specific object type | End-to-end recipes for tables, functions, procedures, triggers, views, indexes, RLS policies, constraints |
| `references/assertions-catalog.md` | Need to know which assertion to use | Full pgTAP assertion catalog (180+) organized by category with NULL behavior and usage notes |
| `references/pg-prove-runner.md` | Running tests, configuring CI, parsing output | `pg_prove` CLI flags, TAP output structure, failure diagnostics, parallel execution, state tracking |
| `references/anti-patterns.md` | Test fails for a non-obvious reason, or before review | Common mistakes (PREPARE leaks, ID assertions, type mismatches), type casting cheat sheet, PostgreSQL error codes |
| `references/advanced-patterns.md` | Testing procedures with COMMIT, RLS with role switching, dynamic SQL, mocking, SECURITY DEFINER, migration equivalence | Workarounds for the transaction control problem, mocking via transactional DDL, role-switching patterns |

### Asset Files — copy from when scaffolding tests

| File | Use when… |
|------|-----------|
| `assets/templates/test-table.sql` | Generating a test file for a table |
| `assets/templates/test-function.sql` | Generating a test file for a function |
| `assets/templates/test-procedure.sql` | Generating a test file for a procedure |
| `assets/templates/test-trigger.sql` | Generating a test file for a trigger |
| `assets/templates/test-view.sql` | Generating a test file for a view |
| `assets/templates/test-rls.sql` | Generating a test file for an RLS policy |
| `assets/templates/test-constraint.sql` | Generating a test file for table constraints |

### Script Files — execute when applicable

| File | Use when… |
|------|-----------|
| `scripts/generate_test_skeleton.py` | The user wants to scaffold a test file from object metadata |
| `scripts/parse_tap_output.py` | Need to extract failures or summary from `pg_prove` output programmatically |

**Loading rule**: Read SKILL.md first. Then read ONLY the specific reference file(s) and copy
ONLY the specific template(s) the current task requires. Never load all references at once.

---

## The Red-Green-Refactor cycle for PostgreSQL

TDD is **not a testing technique** — it's a design methodology that produces tests as a
byproduct. Tests are written *before* the production code they verify.

**RED — Write a failing test.**
- Create a `.sql` test file with pgTAP assertions describing desired structure and behavior.
- Run with `pg_prove` — every new assertion must fail. If something passes, it isn't testing
  new behavior.

**GREEN — Minimal implementation.**
- Write the smallest amount of DDL/DML that makes the failing tests pass.
- Do NOT add columns, indexes, branches, or features not covered by tests.
- Run `pg_prove` again — all tests must pass.

**REFACTOR — Improve while green.**
- Rename, add comments, extract helpers, add performance optimizations (indexes, query
  rewrites, volatility hints).
- Re-run tests after EACH change. If anything breaks, revert.

The cycle should complete in a few minutes. If it stretches into hours, the test is too big —
break it into smaller cycles.

---

## Anatomy of a pgTAP test file

Every pgTAP test file follows this five-line skeleton:

```sql
BEGIN;                          -- 1. Transaction = isolation boundary
SELECT plan(N);                 -- 2. Declare exact assertion count
-- ... assertions go here ...   -- 3. Test assertions
SELECT * FROM finish();         -- 4. Verify plan count matches actual
ROLLBACK;                       -- 5. Undo ALL changes (clean slate)
```

The `BEGIN`/`ROLLBACK` wrapper guarantees complete test isolation: every INSERT, UPDATE, DELETE,
CREATE, and ALTER performed during the test is undone. Tests cannot pollute each other.

**Always use `plan(N)` with an explicit count.** It catches accidentally skipped or duplicated
assertions. Use `no_plan()` only when generating tests dynamically from query results.

**Critical limitation**: procedures that use internal `COMMIT` or `ROLLBACK` end the test's
outer transaction. See `references/advanced-patterns.md` for the three workarounds.

---

## What to test vs what NOT to test

**Test YOUR code.** Constraints you defined, functions you wrote, triggers you built, policies
you configured, views you created.

**Do NOT test PostgreSQL itself.** That `INSERT` works, that `SELECT` returns data, that
arithmetic is correct. PostgreSQL's own regression suite covers this.

| Question | YES → | NO → |
|----------|-------|------|
| Did I write this code? | Test it | Don't test it |
| Does this enforce a business rule? | Test it | Consider skipping |
| Could a migration break this? | Test it | Lower priority |
| Is this a PostgreSQL built-in? | Don't test it | N/A |

---

## Decision tree: routing to the right reference

```
User says…                                    Then…
─────────────────────────────────────────────────────────────────────────────
"test this function / procedure / trigger /  → Read references/object-recipes.md
 view / table / index / RLS policy"            (jump to the matching section)

"which assertion should I use for X?"        → Read references/assertions-catalog.md

"how do I run / configure pg_prove?"         → Read references/pg-prove-runner.md
"what does this TAP output mean?"

"my test fails / passes unexpectedly"        → Read references/anti-patterns.md
"PREPARE leaked / type mismatch /             (cross-check with pg-prove-runner.md
 23505 vs 23502 / row order changed"           for failure diagnostics)

"procedure uses COMMIT internally"           → Read references/advanced-patterns.md
"need to test RLS with multiple roles"
"mock a function inside a test"
"test SECURITY DEFINER"
"validate SQL Server → PostgreSQL migration"

"scaffold a test file for object X"          → Copy assets/templates/test-<type>.sql
                                                AND read object-recipes.md for the
                                                same type to fill in real assertions
```

---

## Coverage strategy per object type (priority by P0 / P1 / P2)

| Object type | Minimum test set | Priority |
|-------------|------------------|----------|
| **Table** | existence, `columns_are`, PK, NOT NULL, FK, UNIQUE, CHECK | P0 |
| **Function** | existence, signature, language, happy path, NULL handling, error cases | P0 |
| **Procedure** | existence, `is_procedure`, happy path side effects, error cases, parameter validation | P0 |
| **Trigger** | existence, `trigger_is`, behavioral effect (data changes) | P1 |
| **View** | existence, `columns_are`, result correctness (`results_eq` / `set_eq`) | P1 |
| **RLS Policy** | `policies_are`, `policy_cmd_is`, role-based access | P1 |
| **Permissions** | `table_privs_are`, `function_privs_are`, `schema_privs_are` | P1 |
| **Index** | existence, type, uniqueness, partial condition | P2 |
| **Materialized View** | existence, `columns_are`, post-refresh correctness | P2 |
| **Type / Enum** | existence, `enum_has_labels` | P2 |

Full per-object recipes: `references/object-recipes.md`.

---

## Standard test file structure

Organize each `.sql` test file into six sections — separators make failures easy to localize:

```sql
BEGIN;
SELECT plan(N);

-- ============================================================
-- SECTION 1: Structure / Existence
-- ============================================================
-- has_table, has_function, columns_are, function_returns, …

-- ============================================================
-- SECTION 2: Setup test data
-- ============================================================
-- INSERTs for the seed data (rolled back at end)

-- ============================================================
-- SECTION 3: Happy path behavior
-- ============================================================
-- is(), set_eq(), lives_ok(), …

-- ============================================================
-- SECTION 4: Edge cases
-- ============================================================
-- NULL parameters, empty datasets, boundary values

-- ============================================================
-- SECTION 5: Error cases
-- ============================================================
-- throws_ok() for constraint violations, RAISE EXCEPTION, perms

-- ============================================================
-- SECTION 6: Cleanup
-- ============================================================
-- DEALLOCATE prepared statements

SELECT * FROM finish();
ROLLBACK;
```

This structure is captured in every template under `assets/templates/`.

---

## Running tests with pg_prove

`pg_prove` is the CLI harness that runs `.sql` test files and aggregates TAP output. The
shortest useful invocation:

```bash
pg_prove -d mydb -U postgres --ext .sql -r tests/
```

Common variants the user will need:

```bash
pg_prove -d mydb -v -r tests/             # verbose: show every assertion
pg_prove -d mydb -j 4 -r tests/           # parallel
pg_prove -d mydb --shuffle -r tests/      # randomize order (catch test pollution)
pg_prove -d mydb --failures -r tests/     # show only failures
pg_prove -d mydb --runtests -s tests      # xUnit-style functions in schema 'tests'
```

Full flag reference and TAP output parsing rules: `references/pg-prove-runner.md`.

For programmatic parsing of `pg_prove` output, run:

```bash
pg_prove ... | python scripts/parse_tap_output.py
```

---

## Workflow for AI agents (high-signal version)

When the user asks to test an object, follow this sequence — do not skip steps:

1. **Identify object type** (table, function, procedure, trigger, view, index, RLS policy, constraint).
2. **Read the matching section** of `references/object-recipes.md`.
3. **Copy the matching template** from `assets/templates/test-<type>.sql` into the user's tests directory.
4. **Fill in real names, types, and seed data** from the user's actual schema.
5. **Run `pg_prove -v`** and report the result. If RED, that's expected before implementation. If unexpectedly GREEN, the assertion isn't testing the right thing — fix it.
6. **For the GREEN phase**, write the minimal DDL/DML to pass.
7. **For the REFACTOR phase**, apply optimizations and re-run tests after each change.

If the agent receives a vague "set up tests for my schema" request, ask which objects to start
with — don't try to scaffold everything at once.

---

## Three-agent TDD architecture (for multi-agent setups)

When orchestrating multiple agents, isolate context to prevent test bias:

| Agent | Phase | Sees | Critical rule |
|-------|-------|------|---------------|
| **Test Writer** | RED | Requirements ONLY | Has NO knowledge of how the implementation will be written |
| **Implementer** | GREEN | Failing test file | Does NOT modify tests |
| **Refactorer** | REFACTOR | Passing code + tests | Runs ALL tests after each change |

Context isolation is mandatory. If the test writer knows the planned implementation, it will
unconsciously write tests that match the implementation rather than the requirement.

---

## Hard rules (apply always)

- **Always** use `plan(N)`, never `no_plan()` (unless tests are dynamically generated).
- **Always** `DEALLOCATE` prepared statements before `finish()`.
- **Always** use `ORDER BY` with `results_eq()`, or prefer `set_eq()` / `bag_eq()`.
- **Always** cast values explicitly in `is()` (e.g., `5::integer`, `99.95::numeric`).
- **Never** assert auto-generated IDs (SERIAL/IDENTITY sequences advance permanently, even
  after ROLLBACK).
- **Never** test PostgreSQL built-in behavior.
- **Always** test NULL parameters explicitly for every function and procedure.
- **Always** include at least one error case (`throws_ok`) for every function/procedure.
- **One file per object** or per concern; max ~30 assertions per file.
- **Naming convention**: `test_<schema>_<object_name>.sql`.

---

## Quick reference: the 12 most-used assertions

These cover ~80% of real test files. Read `references/assertions-catalog.md` for the full set.

| Assertion | Use for |
|-----------|---------|
| `ok(bool, desc)` | Plain boolean check |
| `is(have, want, desc)` | Equality (NULL-safe via `IS NOT DISTINCT FROM`) |
| `isnt(have, want, desc)` | Inequality |
| `throws_ok(sql, errcode, errmsg, desc)` | Verify a specific exception is raised |
| `lives_ok(sql, desc)` | Verify no exception is raised |
| `has_table(schema, table, desc)` | Table existence |
| `has_function(schema, name, args, desc)` | Function existence with signature |
| `columns_are(schema, table, array, desc)` | Exact column list match |
| `col_not_null(schema, table, col, desc)` | NOT NULL constraint check |
| `set_eq(sql, sql, desc)` | Compare result sets (order-insensitive) |
| `is_empty(sql, desc)` | Query returns zero rows |
| `performs_ok(sql, ms, desc)` | Query runs in under N milliseconds |

---

## Common scenarios — quick start

**Scenario: "test this function"**
1. Read `references/object-recipes.md` § Functions.
2. Copy `assets/templates/test-function.sql`.
3. Fill in: schema, function name, argument types, expected return type, happy path inputs,
   NULL handling, at least one `throws_ok`.
4. Run `pg_prove -v` — confirm RED.
5. Implement function — confirm GREEN.

**Scenario: "test this trigger"**
1. Read `references/object-recipes.md` § Triggers.
2. Copy `assets/templates/test-trigger.sql`.
3. Fill in: `has_trigger`, `trigger_is` (correct function), seed → DML → check side effect.

**Scenario: "test RLS policies on this table"**
1. Read `references/advanced-patterns.md` § RLS testing.
2. Copy `assets/templates/test-rls.sql`.
3. Use `SET ROLE` to switch identity. Remember: blocked SELECT returns empty results;
   blocked INSERT/UPDATE/DELETE throws `42501`.

**Scenario: "my test fails with a weird error code"**
1. Read `references/anti-patterns.md` § Error codes table.
2. Cross-check the error code in the diagnostic against the table.
3. If the type mismatch is the issue, see § Type casting rules.

---

**End of SKILL.md.** For anything beyond this surface, route to the appropriate reference file.
