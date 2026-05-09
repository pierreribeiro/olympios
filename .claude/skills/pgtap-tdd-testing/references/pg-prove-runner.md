# pg_prove — Test Runner Reference

`pg_prove` is the command-line harness that discovers, executes, and reports pgTAP tests. It
wraps `psql` and emits TAP (Test Anything Protocol) output. This file covers invocation,
flags, output parsing, and common patterns.

## Table of contents

1. [Quick reference](#1-quick-reference)
2. [Connection flags](#2-connection-flags)
3. [Discovery and execution flags](#3-discovery-and-execution-flags)
4. [Output and reporting flags](#4-output-and-reporting-flags)
5. [State tracking (--state)](#5-state-tracking)
6. [TAP output structure](#6-tap-output-structure)
7. [Failure diagnostics](#7-failure-diagnostics)
8. [xUnit-style execution (--runtests)](#8-xunit-style-execution)
9. [Programmatic parsing](#9-programmatic-parsing)

---

## 1. Quick reference

```bash
# Run all .sql tests recursively, default extension is .pg
pg_prove -d mydb -U postgres --ext .sql -r tests/

# Verbose: show every assertion line, not just file summaries
pg_prove -d mydb -U postgres -v --ext .sql -r tests/

# Run a single file
pg_prove -d mydb tests/functions/test_calc_total.sql

# Run several files in a fixed order
pg_prove -d mydb tests/01-schema.sql tests/02-functions.sql tests/03-triggers.sql

# Parallel execution (CI speedup; tests must be independent)
pg_prove -d mydb -j 4 -r tests/

# Random execution order — surfaces hidden dependencies between tests
pg_prove -d mydb --shuffle --ext .sql -r tests/

# Show only failures (CI summary view)
pg_prove -d mydb --failures --ext .sql -r tests/

# Show timing per test file
pg_prove -d mydb -t --ext .sql -r tests/

# Re-run only previously failed tests
pg_prove -d mydb --state failed,save --ext .sql -r tests/

# Run xUnit-style functions in a schema
pg_prove -d mydb --runtests --schema test_schema
```

---

## 2. Connection flags

| Flag | Meaning |
|------|---------|
| `-d <db>` | Database name (defaults to user's `$PGDATABASE`) |
| `-U <user>` | Username |
| `-h <host>` | Hostname |
| `-p <port>` | Port |
| `-W` | Force password prompt |
| `-w` | Never prompt for password |

`pg_prove` honors all standard libpq env vars: `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`,
`PGDATABASE`, `PGSERVICE`. In CI this is usually cleaner than passing flags everywhere.

---

## 3. Discovery and execution flags

| Flag | Meaning | Default |
|------|---------|---------|
| `-r` / `--recurse` | Recurse into subdirectories | off |
| `--ext <ext>` | File extension to match | `.pg` |
| `-j <N>` / `--jobs <N>` | Parallel jobs | 1 |
| `--shuffle` | Random execution order | off |
| `--reverse` | Reverse alphabetical order | off |
| `-R` / `--runtests` | Use xUnit-style functions instead of files | off |
| `-s` / `--schema <name>` | Schema for xUnit functions | — |
| `--match <regex>` | Run only files matching regex | — |

**Always set `--ext .sql`** unless you've adopted `.pg`. The default `.pg` is a historical
holdover; almost no project uses it.

**Execution order**: alphabetical within each directory, recursing depth-first. Use directory
prefixes (`01-schema/`, `02-functions/`) or filename prefixes (`test_01_users.sql`,
`test_02_orders.sql`) to control ordering when it matters.

**Parallel execution caveat**: tests must be fully independent. If two tests INSERT into the
same temp table or both create a session-level temporary object, `-j 4` will cause flaky
failures. Run with `--shuffle` first to surface dependencies, then add `-j`.

---

## 4. Output and reporting flags

| Flag | Meaning |
|------|---------|
| `-v` / `--verbose` | Show every assertion line, not just file summary |
| `-q` / `--quiet` | Show only file summaries |
| `--failures` | Show only failures |
| `--directives` | Show TODO and SKIP markers in output |
| `--comments` | Show diagnostic lines |
| `-t` / `--timer` | Show elapsed time per file |
| `--archive <dir>` | Save TAP output to a directory |
| `--formatter <name>` | Output format: `Console` (default), `File`, `Color` |

For CI, the typical combination is `-v --failures` — verbose enough to debug, but only when
there's a failure.

---

## 5. State tracking

`--state` lets `pg_prove` remember results between runs. Useful for the "fix-failing-tests"
loop:

| State value | Meaning |
|-------------|---------|
| `failed` | Run only tests that failed last time |
| `passed` | Run only tests that passed last time |
| `hot` | Run tests that have failed in the last N runs |
| `slow` | Run tests in order of execution time (slowest first) |
| `fast` | Slowest last |
| `last` | Run tests in order of last run (most recent first) |
| `save` | Save the state for next invocation |

**Pattern: iterative debugging**:

```bash
pg_prove -d mydb --state save --ext .sql -r tests/    # full run, save state
# (some tests fail)
pg_prove -d mydb --state failed,save --ext .sql -r tests/   # focus on failures
# (fix code, re-run)
pg_prove -d mydb --state failed,save --ext .sql -r tests/   # iterate
# (everything passes)
pg_prove -d mydb --state save --ext .sql -r tests/    # full re-run
```

---

## 6. TAP output structure

A successful run looks like this:

```
tests/structure/test_users_table.sql .. ok
tests/functions/test_calc_total.sql ... ok
tests/triggers/test_audit.sql ......... ok

All tests successful.
Files=3, Tests=27, 1 wallclock secs
( 0.04 usr  0.02 sys +  0.18 cusr  0.03 csys =  0.27 CPU)
Result: PASS
```

In `-v` mode, every assertion appears as `ok N - description` or `not ok N - description`:

```
tests/functions/test_calc_total.sql ..
1..10
ok 1 - calculate_order_total(integer) should exist
ok 2 - should return numeric
ok 3 - should be plpgsql
ok 4 - should be a function, not a procedure or aggregate
ok 5 - order under 100 should have no discount
ok 6 - order over 100 should have 10% discount
ok 7 - order with no items should return 0
ok 8 - non-existent order should return 0
ok 9 - NULL order_id should return NULL
ok 10 - negative order_id should raise P0001
ok
```

**Key markers in TAP output**:

| Pattern | Meaning |
|---------|---------|
| `1..N` | Plan declaration (N tests expected) |
| `ok N - desc` | Assertion N passed |
| `not ok N - desc` | Assertion N failed |
| `# message` | Diagnostic message |
| `# Failed test N: "desc"` | Failure detail |
| `# Looks like you planned X tests but ran Y` | Plan mismatch |
| `Result: PASS` / `Result: FAIL` | Final summary |

---

## 7. Failure diagnostics

pgTAP emits structured diagnostics for failures. The most useful pattern is the `have:` /
`want:` pair from `is`:

```
not ok 5 - function returns correct total
#     Failed test 5: "function returns correct total"
#         have: 54.95
#         want: 55.00
```

For `throws_ok` failures:

```
not ok 7 - should raise error for negative quantity
#     Failed test 7: "should raise error for negative quantity"
#       caught: no exception
#       wanted: P0001
```

Or, when the error code matches but the message doesn't:

```
not ok 8 - should raise specific error
#     Failed test 8: "should raise specific error"
#       caught: 23502: null value in column "email" violates not-null constraint
#       wanted: 23502: email cannot be null
```

For `set_eq` / `bag_eq` failures:

```
not ok 12 - active users
#     Extra records:
#         (1, 'duplicate@test.com')
#     Missing records:
#         (5, 'expected@test.com')
```

For `results_eq` failures:

```
not ok 14
#     Results differ beginning at row 3:
#         have: (1, 'Anna')
#         want: (22, 'Betty')
```

If row counts differ, the missing side appears as `NULL`:

```
not ok 15
#     Results differ beginning at row 5:
#         have: (1, 'Anna')
#         want: NULL
```

If the column types or count differ:

```
not ok 16
#     Number of columns or their types differ between the queries:
#         have: (integer, text)
#         want: (text, integer)
```

**Parsing rule for AI agents**: lines starting with `not ok` are failures; the lines that
immediately follow starting with `#` are the diagnostics for that failure. The `have:` / `want:`
pair is the most actionable — it tells you exactly what you got vs what was expected.

---

## 8. xUnit-style execution

Instead of `.sql` files, you can write test functions and discover them by name:

```sql
CREATE FUNCTION test_schema.startup() RETURNS SETOF TEXT AS $$
    -- runs before every other test function
$$ LANGUAGE plpgsql;

CREATE FUNCTION test_schema.test_users_table() RETURNS SETOF TEXT AS $$
BEGIN
    RETURN NEXT has_table('public', 'users');
    RETURN NEXT col_not_null('public', 'users', 'email');
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION test_schema.shutdown() RETURNS SETOF TEXT AS $$
    -- runs after every other test function
$$ LANGUAGE plpgsql;
```

Run with:

```bash
pg_prove -d mydb --runtests --schema test_schema
```

`runtests()` recognizes these prefixes:
- `startup*` → runs once before any tests
- `setup*` → runs before each test
- `teardown*` → runs after each test
- `shutdown*` → runs once after all tests
- `test*` → the actual test functions

Each test function runs in its own transaction that is rolled back automatically — you do
not need `BEGIN`/`ROLLBACK` inside the function body, and you should not use `plan()` /
`finish()` (`runtests` adds the plan and assertions itself).

**When to choose xUnit over .sql files**: when you have a lot of common setup/teardown logic
and the granularity of "function = one logical test" maps better to your codebase. For most
schema-validation work, plain `.sql` files are simpler.

---

## 9. Programmatic parsing

For CI dashboards or skill-internal use, parse `pg_prove` output rather than re-running tests
to count failures. The general pattern:

```python
# scripts/parse_tap_output.py - simplified version
import re
import sys

PASS_RE = re.compile(r"^ok (\d+)(?: - (.+))?")
FAIL_RE = re.compile(r"^not ok (\d+)(?: - (.+))?")
DIAG_RE = re.compile(r"^#\s+(.+)")

failures = []
current_fail = None
for line in sys.stdin:
    line = line.rstrip()
    m = FAIL_RE.match(line)
    if m:
        current_fail = {"id": int(m.group(1)), "desc": m.group(2), "diag": []}
        failures.append(current_fail)
        continue
    if current_fail and DIAG_RE.match(line):
        current_fail["diag"].append(DIAG_RE.match(line).group(1))
    if PASS_RE.match(line):
        current_fail = None

print(f"Failures: {len(failures)}")
for f in failures:
    print(f"  #{f['id']}: {f['desc']}")
    for d in f["diag"]:
        print(f"      {d}")
```

A more complete version is bundled at `scripts/parse_tap_output.py` and can be invoked as:

```bash
pg_prove -d mydb -v --ext .sql -r tests/ | python scripts/parse_tap_output.py
```

---

## 10. Performance tuning for test runs

In test containers, disable durability features for substantial speedups (test data is ephemeral):

```bash
postgres -c fsync=off -c full_page_writes=off -c synchronous_commit=off
```

For Docker, set this as the container `command:`:

```yaml
postgres:
  image: postgres:17-alpine
  command: postgres -c fsync=off -c full_page_writes=off -c synchronous_commit=off
```

Local dev databases shouldn't have these settings — only test environments.

---

## 11. Common Makefile targets

```makefile
.PHONY: test test-verbose test-failed test-shuffle test-coverage

test:
	pg_prove -d testdb -U postgres --ext .sql -r tests/

test-verbose:
	pg_prove -d testdb -U postgres -v --ext .sql -r tests/

test-failed:
	pg_prove -d testdb -U postgres --state failed,save --ext .sql -r tests/

test-shuffle:
	pg_prove -d testdb -U postgres --shuffle --ext .sql -r tests/

test-parallel:
	pg_prove -d testdb -U postgres -j 4 --ext .sql -r tests/
```

Or for projects using the xUnit pattern:

```makefile
test-xunit:
	pg_prove -d testdb -U postgres --runtests --schema test_schema
```
