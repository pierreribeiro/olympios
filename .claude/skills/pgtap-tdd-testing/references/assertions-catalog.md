# pgTAP Assertions Catalog

Complete catalog of pgTAP assertion functions, organized by category. All assertions return
TEXT (the TAP-formatted result line). Read only the section you need.

## Table of contents

1. [Plan and lifecycle](#1-plan-and-lifecycle)
2. [Core assertions (boolean, equality, regex, comparison)](#2-core-assertions)
3. [Exception and performance](#3-exception-and-performance)
4. [Result-set comparison](#4-result-set-comparison)
5. [Schema existence (has_*  / hasnt_*)](#5-schema-existence)
6. [Schema enumeration (_are functions)](#6-schema-enumeration)
7. [Column and constraint](#7-column-and-constraint)
8. [Index](#8-index)
9. [Function metadata](#9-function-metadata)
10. [Ownership](#10-ownership)
11. [Privileges](#11-privileges)
12. [RLS policies](#12-rls-policies)
13. [Diagnostics and flow control](#13-diagnostics-and-flow-control)

---

## 1. Plan and lifecycle

| Function | Purpose | Notes |
|----------|---------|-------|
| `plan(integer)` | Declare exact assertion count | Errors if actual count differs |
| `no_plan()` | Skip count validation | Use only for dynamic test generation |
| `finish()` | Report plan vs actual | Always call before `ROLLBACK` |
| `finish(true)` | Same, plus throw exception on mismatch | Useful in CI to fail loud |

---

## 2. Core assertions

| Function | Purpose | NULL behavior |
|----------|---------|---------------|
| `ok(boolean, desc)` | Boolean assertion | `NULL` → fail |
| `is(have, want, desc)` | Equality via `IS NOT DISTINCT FROM` | `NULL = NULL` passes |
| `isnt(have, want, desc)` | Inequality via `IS DISTINCT FROM` | `NULL = NULL` fails |
| `matches(have, regex, desc)` | POSIX regex match | |
| `imatches(have, regex, desc)` | Case-insensitive regex | |
| `doesnt_match(have, regex, desc)` | Negative regex | |
| `doesnt_imatch(have, regex, desc)` | Negative case-insensitive regex | |
| `alike(have, like_pattern, desc)` | SQL `LIKE` match | |
| `ialike(have, like_pattern, desc)` | Case-insensitive `LIKE` | |
| `unalike(have, like_pattern, desc)` | Negative `LIKE` | |
| `unialike(have, like_pattern, desc)` | Negative case-insensitive `LIKE` | |
| `cmp_ok(have, op, want, desc)` | Apply any binary operator | `NULL` result → fail |
| `pass(desc)` / `fail(desc)` | Always pass / always fail | Use sparingly |
| `isa_ok(have, regtype, name)` | Type check on a value | |

**Key tip**: prefer `is` over `ok` whenever possible — failing diagnostics are dramatically
more useful (`is` shows have/want, `ok` only shows pass/fail).

---

## 3. Exception and performance

| Function | Purpose |
|----------|---------|
| `throws_ok(sql, errcode, errmsg, desc)` | Verify a specific exception is raised |
| `throws_ok(sql, errcode, desc)` | 3-arg form: 5-byte arg = errcode |
| `throws_ok(sql, errmsg, desc)` | 3-arg form: longer arg = errmsg |
| `throws_ok(sql)` | Just verify SOME exception is raised |
| `throws_like(sql, pattern, desc)` | Exception message matches `LIKE` |
| `throws_ilike(sql, pattern, desc)` | Case-insensitive `LIKE` |
| `throws_matching(sql, regex, desc)` | Exception message matches regex |
| `throws_imatching(sql, regex, desc)` | Case-insensitive regex |
| `lives_ok(sql, desc)` | Verify NO exception is raised |
| `performs_ok(sql, ms, desc)` | Query completes within N ms |
| `performs_within(sql, avg_ms, deviation, iterations, desc)` | Average runtime within window |

**`sql` argument** can be:
- A string with the SQL to execute (`$$INSERT INTO ...$$`)
- The name of a `PREPARE`d statement (no spaces, no quotes)
- A double-quoted prepared statement name (with spaces)

**Always pass `NULL` for the error message** in `throws_ok` unless you control the locale.
PostgreSQL's error messages are localized; relying on the English text breaks tests on
German / Portuguese / etc. installations.

---

## 4. Result-set comparison

| Function | Order matters? | Duplicates count? | Use when |
|----------|---------------|-------------------|----------|
| `results_eq(sql, sql)` | YES | YES | Exact ordered comparison (with `ORDER BY`) |
| `results_ne(sql, sql)` | YES | YES | Verify results differ |
| `set_eq(sql, sql)` | NO | NO | Unordered set equality |
| `set_ne(sql, sql)` | NO | NO | Sets differ |
| `set_has(sql, sql)` | NO | NO | Subset check (sql1 contains sql2's rows) |
| `set_hasnt(sql, sql)` | NO | NO | Exclusion check |
| `bag_eq(sql, sql)` | NO | YES | Unordered, duplicates count |
| `bag_ne(sql, sql)` | NO | YES | Bags differ |
| `bag_has(sql, sql)` | NO | YES | Bag subset |
| `bag_hasnt(sql, sql)` | NO | YES | Bag exclusion |
| `is_empty(sql)` | N/A | N/A | Zero rows |
| `isnt_empty(sql)` | N/A | N/A | At least one row |
| `row_eq(sql, record)` | N/A | N/A | Single-row match against composite type |

**For all of these**, the second `sql` can be replaced with a single-column `ARRAY` if the first
query returns one column:

```sql
SELECT set_eq(
    'SELECT email FROM v_active_users',
    ARRAY['alice@test.com', 'carol@test.com']
);
```

**Don't use `results_eq` without `ORDER BY`** — row order is undefined and tests become flaky.

---

## 5. Schema existence

Every `has_*` has a matching `hasnt_*`. Both take an optional `description` as the last argument
and a schema as the first when applicable.

`has_table`, `has_view`, `has_materialized_view`, `has_sequence`, `has_schema`, `has_extension`,
`has_foreign_table`, `has_column`, `has_index`, `has_trigger`, `has_function`, `has_type`,
`has_composite`, `has_domain`, `has_enum`, `has_role`, `has_user`, `has_group`, `has_language`,
`has_rule`, `has_cast`, `has_operator`, `has_tablespace`, `has_relation`, `has_inherited_tables`

**Common signatures**:

```sql
SELECT has_table('schema', 'table_name', 'description');
SELECT has_function('schema', 'fn_name', ARRAY['arg1_type', 'arg2_type'], 'desc');
SELECT has_column('schema', 'table', 'column', 'desc');
SELECT has_index('schema', 'table', 'index_name', ARRAY['col1', 'col2'], 'desc');
SELECT has_trigger('schema', 'table', 'trigger_name', 'desc');
SELECT has_extension('schema', 'extension_name', 'desc');
SELECT has_extension('extension_name', 'desc');  -- without schema
```

**Cast to NAME when you have only schema + object name**:

```sql
SELECT has_table('myschema'::name, 'mytable'::name);
```

Without the cast, the second argument can be confused with the description string.

---

## 6. Schema enumeration

Verify **exact sets** — extra or missing items fail. These are excellent for catching schema
drift.

`tables_are`, `views_are`, `materialized_views_are`, `columns_are`, `indexes_are`, `triggers_are`,
`functions_are`, `schemas_are`, `sequences_are`, `roles_are`, `users_are`, `groups_are`,
`languages_are`, `types_are`, `domains_are`, `enums_are`, `extensions_are`, `operators_are`,
`rules_are`, `foreign_tables_are`, `partitions_are`, `tablespaces_are`, `opclasses_are`

**Signature pattern**:

```sql
SELECT columns_are(
    'public', 'users',
    ARRAY['id', 'email', 'name', 'active', 'created_at'],
    'users should have exactly these columns'
);

SELECT tables_are(
    'public',
    ARRAY['users', 'orders', 'products'],
    'public should contain exactly these tables'
);
```

**Usage tip**: `_are` functions catch additions you didn't intend (someone adds a column without
updating tests). Pair them with `has_*` for required fields and individual `col_*` for column
constraints.

---

## 7. Column and constraint

### NULL constraints

| Function | Purpose |
|----------|---------|
| `col_not_null(schema, table, col, desc)` | Column is NOT NULL |
| `col_is_null(schema, table, col, desc)` | Column allows NULL |

### Type and default

| Function | Purpose |
|----------|---------|
| `col_type_is(schema, table, col, type, desc)` | Column has expected type |
| `col_has_default(schema, table, col, desc)` | Column has a default value |
| `col_hasnt_default(schema, table, col, desc)` | Column has no default |
| `col_default_is(schema, table, col, default, desc)` | Default matches expected expression |

**Type names must match PostgreSQL's internal form**: `character varying(255)`, not
`varchar(255)`. Aliases work for the canonical type name (e.g., `integer` and `int4`), but for
parameterized types you usually want the full canonical form. Check actual stored type with:

```sql
SELECT format_type(atttypid, atttypmod) FROM pg_attribute
WHERE attrelid = 'public.users'::regclass AND attname = 'email';
```

### Primary key, foreign key, unique, check

| Function | Purpose |
|----------|---------|
| `has_pk(schema, table, desc)` | Table has a primary key |
| `hasnt_pk(schema, table, desc)` | Table does NOT have a primary key |
| `col_is_pk(schema, table, col_or_array, desc)` | Specified column(s) form the PK |
| `has_fk(schema, table, desc)` | Table has at least one FK |
| `col_is_fk(schema, table, col_or_array, desc)` | Specified column(s) are part of an FK |
| `fk_ok(fk_schema, fk_table, fk_col, pk_schema, pk_table, pk_col, desc)` | FK references the right PK |
| `has_unique(schema, table, desc)` | Table has at least one UNIQUE constraint |
| `col_is_unique(schema, table, col_or_array, desc)` | Specified column(s) are UNIQUE |
| `has_check(schema, table, desc)` | Table has at least one CHECK constraint |
| `col_has_check(schema, table, col_or_array, desc)` | CHECK exists on the specified column(s) |

`fk_ok` is preferred over `col_is_fk` because it verifies the entire relationship in one call.

---

## 8. Index

| Function | Purpose |
|----------|---------|
| `has_index(schema, table, index, columns_array, desc)` | Index exists with specified columns |
| `index_is_type(schema, table, index, type, desc)` | Index uses btree / hash / gin / gist |
| `index_is_unique(schema, table, index, desc)` | Index enforces uniqueness |
| `index_is_primary(schema, table, index, desc)` | Index backs the primary key |
| `index_is_partial(schema, table, index, desc)` | Index has a WHERE clause |
| `is_indexed(schema, table, col_or_array, desc)` | Some index covers these columns |
| `is_clustered(schema, table, index, desc)` | Table is clustered on this index |

For column expressions in indexes (e.g., `lower(email)`), match PostgreSQL's internal form:
all SQL keywords lowercase, non-functional expressions wrapped in parens.

---

## 9. Function metadata

| Function | Purpose |
|----------|---------|
| `function_returns(schema, fn, args, type, desc)` | Function return type |
| `function_lang_is(schema, fn, args, lang, desc)` | Implementation language |
| `is_definer(...)` / `isnt_definer(...)` | SECURITY DEFINER vs INVOKER |
| `is_strict(...)` / `isnt_strict(...)` | STRICT volatility |
| `is_normal_function(...)` / `isnt_normal_function(...)` | Normal vs aggregate/window/procedure |
| `is_aggregate(...)` / `isnt_aggregate(...)` | Aggregate function |
| `is_window(...)` / `isnt_window(...)` | Window function |
| `is_procedure(...)` / `isnt_procedure(...)` | Procedure (vs function) |
| `volatility_is(schema, fn, args, level, desc)` | VOLATILE / STABLE / IMMUTABLE |
| `trigger_is(schema, table, trg, fn_schema, fn, desc)` | Trigger calls expected function |
| `can(schema, functions_array, desc)` | All functions in array exist |

**For the return type**, use `'setof <type>'` (lowercase!) for set-returning functions, and
`'void'` for procedures.

---

## 10. Ownership

| Function | Purpose |
|----------|---------|
| `db_owner_is(dbname, user, desc)` | Database owned by user |
| `schema_owner_is(schema, user, desc)` | Schema owner |
| `tablespace_owner_is(tablespace, user, desc)` | Tablespace owner |
| `relation_owner_is(schema, relation, user, desc)` | Relation (table/view/seq/etc.) owner |
| `table_owner_is(schema, table, user, desc)` | Table owner |
| `view_owner_is(schema, view, user, desc)` | View owner |
| `materialized_view_owner_is(schema, mv, user, desc)` | Materialized view owner |
| `sequence_owner_is(schema, seq, user, desc)` | Sequence owner |
| `composite_owner_is(schema, type, user, desc)` | Composite type owner |
| `foreign_table_owner_is(schema, ft, user, desc)` | Foreign table owner |
| `index_owner_is(schema, table, index, user, desc)` | Index owner |
| `function_owner_is(schema, fn, args, user, desc)` | Function owner |
| `language_owner_is(language, user, desc)` | PL owner |
| `opclass_owner_is(schema, opclass, user, desc)` | Operator class owner |
| `type_owner_is(schema, type, user, desc)` | Type owner |

---

## 11. Privileges

| Function | Privileges array values |
|----------|-------------------------|
| `database_privs_are(db, role, privs, desc)` | `CREATE`, `CONNECT`, `TEMPORARY` |
| `tablespace_privs_are(ts, role, privs, desc)` | `CREATE` |
| `schema_privs_are(schema, role, privs, desc)` | `CREATE`, `USAGE` |
| `table_privs_are(schema, table, role, privs, desc)` | `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `REFERENCES`, `TRIGGER`, `RULE` |
| `sequence_privs_are(schema, seq, role, privs, desc)` | `SELECT`, `UPDATE`, `USAGE` |
| `column_privs_are(schema, table, col, role, privs, desc)` | `SELECT`, `INSERT`, `UPDATE`, `REFERENCES` |
| `any_column_privs_are(schema, table, role, privs, desc)` | At least one column with these privs |
| `function_privs_are(schema, fn, args, role, privs, desc)` | `EXECUTE` |
| `language_privs_are(lang, role, privs, desc)` | `USAGE` |
| `fdw_privs_are(fdw, role, privs, desc)` | `USAGE` |
| `server_privs_are(server, role, privs, desc)` | `USAGE` |

Diagnostics on failure list extra and missing privileges separately, so you immediately see what
to GRANT or REVOKE.

---

## 12. RLS policies

| Function | Purpose |
|----------|---------|
| `policies_are(schema, table, policies_array, desc)` | Exact set of policies |
| `policy_roles_are(schema, table, policy, roles_array, desc)` | Roles policy applies to |
| `policy_cmd_is(schema, table, policy, command, desc)` | Command (`select`/`insert`/`update`/`delete`/`all`) |

For role-switching tests of actual RLS behavior, see `references/advanced-patterns.md` § 3.

---

## 13. Diagnostics and flow control

| Function | Purpose |
|----------|---------|
| `diag(text)` | Print diagnostic line (TAP `#` prefix) |
| `skip(why, count)` | Skip the next N tests |
| `todo(why, count)` | Mark next N tests as TODO (expected to fail) |
| `todo_start(why)` | Begin a TODO block |
| `todo_end()` | End a TODO block |
| `in_todo()` | Check if currently in a TODO block |
| `collect_tap(...)` | Collect multiple assertions for conditional execution |
| `runtests([schema], [pattern])` | Run xUnit-style test functions |
| `findfuncs(schema, pattern, exclude)` | Discover test functions by regex |

**`skip` pattern** for version-conditional tests:

```sql
SELECT CASE WHEN current_setting('server_version_num')::int < 100000
    THEN skip('partition support requires PG 10+', 2)
    ELSE collect_tap(
        is_partitioned('public', 'mylog'),
        partitions_are('public', 'mylog', ARRAY['mylog_2024', 'mylog_2025'])
    )
    END;
```

`collect_tap` is the way to run multiple assertions inside a single `CASE` branch — without it
you can only return one assertion per branch.
