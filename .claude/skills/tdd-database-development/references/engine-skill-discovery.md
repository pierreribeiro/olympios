# Engine Skill Discovery — Find the Engine-Specific TDD Skill

Read this **before** writing any engine-specific syntax. This skill (`tdd-database-
development`) is engine-agnostic on purpose — it teaches the methodology, the roles, and
the patterns. The actual test framework, assertion library, and runner come from a
**separate, engine-specific** skill. Examples:

| Database engine | Likely engine-specific skill |
|------------------|------------------------------|
| PostgreSQL | `pgtap-tdd-testing` |
| Oracle | `utplsql-tdd-testing` (uses utPLSQL) |
| SQL Server | `tsqlt-tdd-testing` (uses tSQLt) |
| MySQL / MariaDB | `mytap-tdd-testing` (uses MyTAP) |
| SQLite | `sqlite-tdd-testing` |
| BigQuery | `bigquery-tdd-testing` (dataform / dbt-style) |
| Snowflake | `snowflake-tdd-testing` |
| DuckDB | `duckdb-tdd-testing` |

This skill assumes the engine-specific skill exists. If it does not, you fall back to
pseudo-code only — and **flag this explicitly in the report**.

---

## Step 1 — Identify the engine

Information sources, in order of reliability:

1. **The orchestrator's prompt** — most direct. *"Use Oracle 19c"*, *"PostgreSQL 16"*.
2. **A connection string in scope** — `postgresql://`, `mysql://`, `oracle://`,
   `mssql://`, `bigquery://`, `snowflake://`. Schemes are unambiguous.
3. **A configuration file in scope** — `dbt_project.yml`, `liquibase.properties`,
   `flyway.conf`, `tnsnames.ora`, `pg_hba.conf`, environment files referencing
   engine-specific drivers (`psycopg2`, `cx_Oracle`, `pyodbc`, etc.).
4. **A migration framework in use** — `alembic` (any), `goose`, `flyway` (any),
   `liquibase` (any), `db-migrate`, `knex`, `prisma`. Tells you the family but not
   always the specific engine.
5. **DDL in the schema** — engine-specific syntax (`CREATE OR REPLACE PACKAGE` →
   Oracle, `WITH (DISTKEY=...)` → Redshift, `CLUSTER BY` → BigQuery/Snowflake).
6. **Process / driver evidence** — running processes (`postgres`, `oracle`, `mssqlserver`,
   `mariadbd`), installed CLIs (`psql`, `sqlcl`, `sqlplus`, `sqlcmd`, `mysql`, `bq`).

Combine evidence. A single source can mislead (a `dbt_project.yml` may target Postgres
or Snowflake or BigQuery — the `profile` block tells you which).

If you cannot determine the engine with high confidence, **stop and ask the
orchestrator**. Pseudo-code without a target engine is fine for a plan but cannot
produce a runnable test.

---

## Step 2 — Locate the engine-specific TDD skill

Once you know the engine, look for a skill whose name follows the convention
`<framework>-tdd-testing` or `<engine>-tdd-testing`. Search:

1. **Available skills list** in your environment (most direct).
2. **Skill registry** — wherever the orchestrator's skill loader publishes the catalog.
3. **The orchestrator's project** — a `skills/` or `.claude/skills/` directory.
4. **Ask the orchestrator** — *"Which engine-specific TDD skill should I load?"*

The engine-specific skill provides:

- **Test harness** — how to declare a test, plan, lifecycle (BEGIN/finish/ROLLBACK).
- **Assertion catalog** — what `ASSERT object_exists`, `ASSERT row_eq`,
  `ASSERT throws_with_code` translate to in this engine's syntax.
- **Isolation strategy** — how the test rolls back / cleans up.
- **Runner** — how to invoke the suite from the command line.
- **Failure diagnostics** — how to read the engine's TAP / xUnit / native output.

This skill (`tdd-database-development`) tells you **what to test and why**; the
engine-specific skill tells you **how to write the test in this engine's syntax**.

---

## Step 3 — Validate the engine-specific skill is appropriate

When you find a candidate engine-specific skill, do a quick sanity check before relying
on it. Read its `SKILL.md` and confirm:

- It targets the same engine you identified.
- It targets a compatible **version** (check version constraints if any).
- It declares the assertion / lifecycle primitives you intend to use.
- It is not deprecated or marked superseded.

If multiple candidate skills exist (e.g., two PostgreSQL skills), prefer the one named
in the orchestrator's prompt; otherwise the more specific / more recently updated one.

---

## Step 4 — Use the two skills together

Within your role's work:

```
load:  tdd-database-development          (this skill — methodology + role)
load:  <engine>-tdd-testing              (engine-specific — syntax + runner)

write: pseudo-code AAA structure          (from this skill's aaa-pattern-database.md)
       └─ translate to engine syntax     (from engine-specific assertion catalog)

run:   the engine-specific runner         (per the engine skill)

assert: behavior, not implementation      (this skill)
        with engine's assertion functions (engine skill)
```

Neither skill alone is sufficient. This skill without the engine skill produces
pseudo-code that is conceptually correct but not runnable. The engine skill without
this one produces tests that may pass but do not honor TDD discipline (one behavior per
test, AAA, baby steps, etc.).

---

## Step 5 — When no engine-specific skill exists

This happens. Engines are many; skills are few. Fallback options, ordered:

1. **Use the engine's native test framework directly**. PostgreSQL has `pgTAP`. Oracle
   has `utPLSQL`. SQL Server has `tSQLt`. MySQL has `MyTAP`. SQLite has anonymous
   blocks; many CI tools build on top. Read the framework's documentation and write
   tests by hand, applying this skill's discipline.
2. **Use a generic SQL test framework**. `dbt test` and `Great Expectations` work across
   engines for data-quality assertions; less suited for full RGR cycles but useful for
   structural tests.
3. **Use application-level testing**. If the database object is invoked through an app
   layer, write integration tests in the app's test framework (pytest, JUnit, vitest,
   Go's `testing`, etc.) that exercise the database object end-to-end. This is slower
   feedback but works everywhere.
4. **Pseudo-code only — flag explicitly**. Capture the test as plan-level pseudo-code in
   the RED phase. This is **not** a runnable test. Mark it clearly in the report:

   ```
   ⚠ PSEUDO-CODE ONLY: no engine-specific test skill found for <engine>.
   This test cannot be executed by the suite as-is. The orchestrator must
   either provide an engine-specific skill, accept manual translation, or
   use one of the fallback approaches above.
   ```

   The orchestrator decides whether to proceed.

---

## What to put in your plan and report

In **plan**:

```
## Engine + engine-specific skill
- engine: <name + version>
- engine-specific skill: <name>  (loaded: yes / no / fallback: <which>)
- pseudo-code only: <yes / no>
```

In **report**:

```
## Engine + engine-specific skill
- engine confirmed: <name + version>
- engine-specific skill used: <name>
- fallback applied: <none | utPLSQL direct | dbt test | application-level | pseudo-code only>
- runtime translation notes: <one line if anything was non-trivial>
```

These two sections are mandatory. They survive across runs and let any subsequent
sub-agent (or human reviewer) see exactly which test technology was in play.

---

## Cross-engine portability is NOT a goal of TDD tests

A note on a recurring confusion: TDD tests are scoped to **one** target engine. The
test for "PostgreSQL function X returns Y" is written in PostgreSQL with PostgreSQL
assertions. There is no generic "database test" that runs on any engine. Cross-engine
portability is a property of the schema and the application, not of the test suite.

If your project uses multiple engines (e.g., Postgres in dev, BigQuery in production —
a real and miserable scenario), each engine has its own test suite written with its
own engine-specific skill. The two suites assert similar behavior, but they are not the
same code.

---

## Quick reference

```
1. Identify engine               (prompt → connection string → config → DDL → process)
2. Find engine-specific skill    (catalog → project skills/ → ask orchestrator)
3. Validate skill                (engine match, version match, primitives match)
4. Use both                      (this skill = WHAT/WHY; engine skill = HOW)
5. No engine skill?              (native framework → generic → app-level → pseudo only)
6. Document in plan + report     (engine, skill, fallback, notes)
```

---

## See also

- `role-red-test-writer.md` — uses this when writing tests
- `role-green-implementer.md` — uses this when writing implementation
- `role-refactor-refactorer.md` — uses this when applying changes
- The engine-specific TDD skill — the other half of the picture
