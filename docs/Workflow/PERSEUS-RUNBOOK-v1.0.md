# PERSEUS RUNBOOK · v1.0

**Audience:** Claude Code · **SOT:** WORKFLOW-PERSEUS-v3.0.md · **Updated:** 2026-05-11

Operational flow. Commands and decisions only. No rationale. Refer SOT for explanations.

---

## §1 · Mode Detection

```
INPUT: <object-name>, <object-type>  (e.g., sp_users_grant, procedure)

IF EXISTS source/original/pgsql-gemini-converted/<type>/<object>.sql
    → MODE = BROWNFIELD       → goto §2
ELIF EXISTS source/original/sqlserver/<type>/<object>.sql
    → MODE = GREENFIELD       → goto §2
ELSE
    → HALT. WAIT PIERRE.      → see §9 case 1
```

---

## §2 · Worktree Instrumentation

```
1. git gtr new <branch>                       # postCreate fires; DB cloned ~200ms
2. test -f $PERSEUS_BASE/<worktree>/.env || HALT
3. cd $PERSEUS_BASE/<worktree>
4. set -a && . .env && set +a                 # load env into shell
```

**Verify:** `pg_isready -h $PGHOST -p $PGPORT` returns success. Else HALT.

---

## §3 · Cockpit Open

```
./scripts/gtr-tmux.sh <worktree>              # 2 panes: orchestrator + cc-agents
```

Pane 0 = self (orchestrator). Pane 1 = subagent visibility (auto, via PostToolUse hook).

---

## §4 · Phase 0 (BROWNFIELD only)

Skip entire §4 if MODE = GREENFIELD. Jump to §5.

### §4.1 · Resource Intake

```
1. List SDD artifacts for <object>: specs, design docs, prior reports
2. Write tdd-cycles/<feature>/00-discovery/resources.md
   Classify each: complete | partial | absent
```

### §4.2 · Discovery

```
1. For each artifact:
     complete → reuse as-is
     partial  → gap-fill missing sections
     absent   → survey codebase (consumers, callers, dependents)

2. Read current implementation:
     source/original/pgsql-gemini-converted/<type>/<object>.sql

3. Write tdd-cycles/<feature>/00-discovery/inventory.md:
     - Consumers (procedures, views, triggers calling this object)
     - Blast radius
     - Object SHA + timestamp → version-lock.md
```

### §4.3 · Preserve/Change List Gate

```
PROMPT PIERRE:
  "Reviewed inventory. Please confirm:
   - PRESERVE list: <list candidate behaviors to keep as-is>
   - CHANGE list:   <list candidate behaviors to modify>"

WAIT PIERRE.
```

### §4.4 · Characterization

```
DISPATCH tdd-test-writer characterize MODE
  IN:  current_impl=source/original/pgsql-gemini-converted/<type>/<object>.sql,
       inventory=tdd-cycles/<feature>/00-discovery/inventory.md,
       preserve_list=<Pierre's confirmed list>
  OUT: tdd-cycles/<feature>/00-characterization/
         ├── characterize.plan.md
         ├── characterize.report.md
         └── tests/*.sql
```

### §4.5 · Phase 0 Gate

```
1. Run: ./scripts/run-pgtap.sh tdd-cycles/<feature>/00-characterization/tests/
2. ALL GREEN on first run?
     YES → goto §4.6
     NO  → fix the TEST (not the code). Re-dispatch §4.4. Iterate until green.
```

### §4.6 · Pierre Approval

```
PROMPT PIERRE:
  "Phase 0 complete. <N> characterization tests passing.
   Preserve/change list confirmed. Proceed to RGR?"

WAIT PIERRE.
```

After approval → §5.

---

## §5 · RGR Inner Loop

Run once per behavior in CHANGE list (brownfield) or per behavior in decomposed spec (greenfield).

```
SETUP:
  CYCLE_DIR = tdd-cycles/<feature>/<NNN>-<behavior-slug>/
  mkdir -p $CYCLE_DIR
```

### §5.1 · 🔴 RED

```
DISPATCH tdd-test-writer red MODE
  IN:  behavior_spec=<spec text or path>,
       inventory=tdd-cycles/<feature>/00-discovery/inventory.md  (brownfield only)
  OUT: $CYCLE_DIR/red.plan.md,
       $CYCLE_DIR/red.report.md,
       tests/{schema|procedures}/<test-file>.sql

GATE: ./scripts/run-pgtap.sh tests/
  Test fails for the RIGHT reason (missing behavior, not syntax error)?
    YES → goto §5.2
    NO  → re-dispatch §5.1 with corrected spec
```

### §5.2 · 🟢 GREEN

```
DISPATCH tdd-implementer
  IN:  test_file=<path from §5.1 OUT>,
       business_context=<minimal natural-language description>
  OUT: $CYCLE_DIR/green.plan.md,
       $CYCLE_DIR/green.report.md,
       source/building/pgsql/refactored/<type>/<object>.sql

⚠️  CRITICAL: Do NOT pass red.plan.md or RED's chain-of-thought.
    Pass only the test file path + business context.

GATE: ./scripts/run-pgtap.sh tests/
  Full suite (characterization + new) green?
    YES → goto §5.3
    NO  → re-dispatch §5.2
```

### §5.3 · 🔵 REFACTOR

```
DISPATCH tdd-refactorer
  IN:  green_report=$CYCLE_DIR/green.report.md,
       impl=source/building/pgsql/refactored/<type>/<object>.sql,
       full_test_suite=tests/
  OUT: $CYCLE_DIR/refactor.plan.md,
       $CYCLE_DIR/refactor.report.md,
       updated impl file

GATE: ./scripts/run-pgtap.sh tests/
  Suite still green?
    YES → cycle done. Next behavior or goto §6.
    NO  → REVERT refactor. Behavior change is a separate RED cycle, not a refactor.
```

### §5.4 · Behavior Loop

```
More behaviors in CHANGE list (brownfield) or spec (greenfield)?
  YES → increment <NNN>, repeat §5
  NO  → goto §6
```

---

## §6 · Equivalence Check (BROWNFIELD only)

```
1. Run full union: ./scripts/run-pgtap.sh tests/
2. ALL GREEN?
     YES → goto §7
     NO  → HALT. Diagnose regression.
```

Greenfield: skip §6, go to §7.

---

## §7 · Final Artifacts Verification

```
Confirm files exist and have content:
  source/building/pgsql/refactored/<type>/<object>.sql
  tdd-cycles/<feature>/<NNN>-<slug>/red.{plan,report}.md     # per cycle
  tdd-cycles/<feature>/<NNN>-<slug>/green.{plan,report}.md   # per cycle
  tdd-cycles/<feature>/<NNN>-<slug>/refactor.{plan,report}.md # per cycle
  tdd-cycles/<feature>/00-characterization/                  # brownfield only

Generate cycle summary:
  echo "..." > tdd-cycles/<feature>/SUMMARY.md
```

---

## §8 · Pierre Review

```
PROMPT PIERRE:
  "Work complete:
   - <N> cycles run
   - <M> tests passing (X characterization + Y new)
   - Quality score: <score>/10
   - Artifact: source/building/pgsql/refactored/<type>/<object>.sql
   Review and approve commit?"

WAIT PIERRE.
```

If revision requested → loop back to relevant §5 cycle.
If rejected → coordinate with Pierre. Possibly `gtr rm`.
If approved → §9.

---

## §9 · Commit & PR

```
1. git add -A
2. git commit -m "$(cat <<EOF
<type>: <object> migration

Mode: <BROWNFIELD|GREENFIELD>
Phase 0: <N characterization tests captured>     # brownfield only
Behaviors: <list of cycles run>
Tests: <X characterization + Y new = Z total, all green>
Quality: <score>/10

Co-authored-by: Claude <claude@anthropic.com>
EOF
)"

3. gh pr create \
     --title "<branch>" \
     --body-file tdd-cycles/<feature>/SUMMARY.md \
     --base main

4. PROMPT PIERRE: "PR opened: <url>. Merge when ready."
   WAIT PIERRE.
```

---

## §10 · Cleanup

```
DEFAULT: Pierre executes manually. Do not auto-cleanup.

IF Pierre explicitly requests cleanup:
  git gtr rm <worktree>                       # preRemove fires; DB dumped + dropped
```

---

## §A · Subagent Dispatch Template

The literal pattern for every Task tool invocation. **Paths-not-prose discipline.**

```
DISPATCH <agent-name> [<mode>] MODE
  IN:  <key>=<absolute or repo-relative path>,
       <key>=<path>,
       <key>=<short text fragment ONLY if no file exists>
  OUT: <expected output path 1>,
       <expected output path 2>

PROMPT TO SUBAGENT (skeleton):
  "You are <agent-name> in <mode> mode.
   Read inputs at:
     - <path 1>
     - <path 2>
   Produce outputs at:
     - <path 3>
     - <path 4>
   Follow your skill K1 (tdd-database-development) and K2 (pgtap-tdd-testing).
   Do not read any other files unless they are dependencies of inputs.
   Return when outputs are written and gate condition satisfied."
```

**IRON RULE for orchestrator (this is you, Claude):**
- Pass **PATHS**, not chain-of-thought from prior subagents.
- GREEN does NOT see RED's reasoning. Only RED's test file.
- REFACTOR does NOT see RED or GREEN's plan.md. Only green.report.md + test suite.
- Cross-cycle context is forbidden.

---

## §B · Halt Conditions Quick Reference

| Case | Trigger | Action |
|---|---|---|
| 1 | Object absent in both `pgsql-gemini-converted/` and `sqlserver/` | HALT. Ask Pierre for source. |
| 2 | Phase 0 inventory complete, preserve/change list needed | PROMPT PIERRE. WAIT. |
| 3 | All cycles complete, pre-commit review | PROMPT PIERRE. WAIT. |
| 4 | PR opened, awaiting merge | PROMPT PIERRE. WAIT. |
| 5 | Worktree cleanup decision | DEFAULT no-op. Cleanup only on explicit Pierre request. |

---

## §C · Path Reference (memorize)

```
INPUTS (read-only):
  source/original/sqlserver/<type>/<object>.sql                  # T-SQL (greenfield src)
  source/original/pgsql-gemini-converted/<type>/<object>.sql     # PG converted (brownfield src)

OUTPUTS:
  source/building/pgsql/refactored/<type>/<object>.sql           # final artifact
  tdd-cycles/<feature>/00-discovery/{resources,inventory,version-lock}.md
  tdd-cycles/<feature>/00-characterization/{plan,report}.md + tests/
  tdd-cycles/<feature>/<NNN>-<slug>/{red,green,refactor}.{plan,report}.md
  tdd-cycles/<feature>/SUMMARY.md
  tests/schema/<test>.sql        # BEGIN/ROLLBACK isolation
  tests/procedures/<test>.sql    # ephemeral DB isolation (<3s cycle)

ASSETS:
  agents/{tdd-test-writer,tdd-implementer,tdd-refactorer}.md
  skills/{tdd-integration,tdd-database-development,pgtap-tdd-testing}/
  .claude/hooks/{tdd-skill-forced-eval,agent-visibility}.sh
  scripts/{gtr-tmux,run-pgtap,provision-branch-db,deprovision-branch-db}.sh
  scripts/gtr-hooks/{postCreate,preRemove}.sh
```

---

**END OF RUNBOOK · v1.0**

For rationale, troubleshooting, setup, or migration history → WORKFLOW-PERSEUS-v3.0.md
