# Plan and Report Protocol — Mandatory for Every Sub-Agent

Read this when starting or finishing any role. The plan-then-act-then-report contract is
**mandatory**. It exists for two reasons:

1. **Forces the sub-agent to think before acting** — the most-skipped step in AI-driven
   work, and the one most directly tied to over-engineering and YAGNI violations.
2. **Makes the work auditable and re-runnable** — when a cycle fails or the orchestrator
   asks for a retry, the report carries the context forward. No re-derivation.

---

## The contract — three steps, every time

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  1. PLAN     →  fill in role-plan-template.md              │
│  2. ACT      →  do the work prescribed by your role        │
│  3. REPORT   →  fill in / update role-report-template.md   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

The plan is short (≤ 1 page). The report is short (≤ 1 page for a normal cycle). Brevity
is a feature — the sub-agent's outputs are read by the orchestrator, future sub-agents,
and humans. Long documents are skipped; short ones are read.

---

## Where the files live

The orchestrator decides the directory. A common layout:

```
<project root>/
  tdd-cycles/
    <feature-name>/
      <NNN>-<short-behavior-slug>/
        red.plan.md       ← RED sub-agent's plan (mandatory)
        red.report.md     ← RED sub-agent's report (mandatory)
        green.plan.md     ← GREEN sub-agent's plan
        green.report.md   ← GREEN sub-agent's report
        refactor.plan.md  ← REFACTOR sub-agent's plan
        refactor.report.md← REFACTOR sub-agent's report
```

If the orchestrator does not specify, propose this layout in your first plan and ask.

---

## The plan — written BEFORE you act

Use `assets/templates/role-plan-template.md`. The template asks for:

- **Behavior under test / under implementation / under refactor** — one sentence.
- **Inputs received** — what the orchestrator gave you (file paths, prior reports,
  engine name, behavior description).
- **Engine + engine-specific skill** — name + whether it was found and loaded; flag if
  pseudo-code only.
- **Plan steps** — numbered, ≤ 5 items. Each item is concrete enough that a peer could
  execute it.
- **What you will explicitly NOT do this cycle** — anti-YAGNI guard rail. List the
  related changes you are deferring.
- **Open questions / flags** — anti-patterns spotted, ambiguities, blockers.
- **Expected outcome** — the failure (RED) / pass + green suite (GREEN) / improvement
  set or "no refactor" (REFACTOR).

If you cannot fill in *any* required field, you do not have enough context to start.
Stop and ask the orchestrator.

### Plan length rules

- Each section is 1–3 lines.
- Total length ≤ 1 page (≈ 50 lines including blank lines and headings).
- Code/SQL fragments are pseudo-code, dialect-neutral.
- No sub-headings beyond what the template provides.

---

## The report — written / updated AFTER you act

Use `assets/templates/role-report-template.md`. The template asks for:

- **Status** — one of: `success`, `partial`, `blocked`, `flagged`.
- **Behavior** — one-sentence restatement (must match the plan).
- **Files touched** — bulleted list with one-line description per file.
- **Test run output** — captured verbatim or summarized, with the result on the last
  line (`fail`, `pass`, etc., as required by the role).
- **Decisions made** — short bullets explaining choices the orchestrator should know.
- **Anti-pattern flags** — anything from `database-anti-patterns.md` you spotted (and
  whether you flagged-and-stopped or flagged-and-proceeded with explicit override).
- **Deferred** — what you intentionally did NOT do (must match the plan's "will not do"
  section, or note divergences).
- **Open questions for the orchestrator** — anything that needs human or coordinator
  judgment.
- **Hand-off** — the next role's expected input (e.g., RED's report says "GREEN should
  start with this failing test path: ...").

### Report length rules

- 1 page for a normal cycle.
- 2 pages maximum for a complex cycle with flags / blockers.
- If you are writing more, you are reasoning in the report instead of the work.

---

## Update-on-repeat semantics

If your role is **re-run on the same behavior** — for example, RED writes a test, GREEN
fails to make it pass, the orchestrator sends RED back to refine the test — you
**update** the existing report rather than creating a new one.

```
red.report.md (existing)
└── append a new section:

  ## Run 2 — <ISO timestamp>
  - Reason for re-run: <orchestrator's reason>
  - Changes since Run 1: <what you did differently>
  - <... rest of report fields, only fields that changed>
```

Likewise the plan: append a `## Run N` section rather than overwriting the prior plan.
The history is the audit trail.

This applies to all three roles. RED, GREEN, REFACTOR can each be re-run any number of
times within the same cycle. The plan and report files persist; their content grows
forward in time.

---

## When the report disagrees with the plan

If during execution you discover the plan was wrong (e.g., you planned to test an
existing behavior but discovered the behavior is not yet present, or the plan committed
to one approach but a hard constraint forced another), the report records the
divergence:

- Quote the plan section that was wrong.
- Explain why it had to change.
- Describe what was actually done.

Do **not** silently rewrite the plan after acting. The mismatch is the audit trail.

---

## Hand-off — what each role's report leaves behind

| Role | The next consumer | What the report must give them |
|------|-------------------|--------------------------------|
| 🔴 RED | the orchestrator → 🟢 GREEN | path to failing test, failure output, behavior in one sentence |
| 🟢 GREEN | the orchestrator → 🔵 REFACTOR | paths to modified implementation files, full-suite green output |
| 🔵 REFACTOR | the orchestrator → next 🔴 RED (or "feature done") | confirmation tests are still green; either changes summary or "no refactor" reason |

A clean hand-off is the difference between a smooth cycle and a debugging session.

---

## Brevity discipline — what NOT to put in plans/reports

- Methodology recap. The reader knows TDD; this is operational, not educational.
- Engine syntax. The engine-specific skill carries that. Pseudo-code is enough for
  plan/report context.
- Long quotes from references. Cite by filename and section instead.
- Rationalization. If you skipped a step, say so plainly. Do not justify.
- Future plans. The plan is for *this* cycle. Future work is the orchestrator's.

---

## Failure modes — what to do when…

| Situation | Action |
|-----------|--------|
| Cannot identify your role | Stop. Ask orchestrator. Do not write plan or act. |
| Plan reveals the request needs splitting | Stop. Document the split in the plan. Return to orchestrator without acting. |
| Plan reveals an anti-pattern is being requested | Stop. Document in plan. Return to orchestrator. |
| Test fails for a reason the plan did not anticipate | Update plan with `## Run 2`, then act. |
| You ran out of context budget | Write what you have to the report with `status: partial`. The next run can pick up. |

---

## The five-line distillation

```
PLAN before ACT before REPORT.
Plan ≤ 1 page. Report ≤ 1 page (2 max).
Re-run = append a "## Run N" section, never overwrite.
Hand-off = next consumer can resume without asking.
Pseudo-code in plan/report; engine syntax in code only.
```

---

## See also

- `assets/templates/role-plan-template.md` — the plan template you fill in
- `assets/templates/role-report-template.md` — the report template you fill in
- Role files: `role-red-test-writer.md`, `role-green-implementer.md`,
  `role-refactor-refactorer.md`
