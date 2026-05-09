# Role Report — `<RED | GREEN | REFACTOR>` — Run 1

> **Mandatory** after the sub-agent acts. Keep ≤ 1 page (2 max for blocked / flagged).
> If you re-run this role, **append** a `## Run 2` section rather than overwriting.
> See `references/plan-and-report-protocol.md`.

---

## Status

`<success | partial | blocked | flagged>`

---

## Behavior

> One-sentence restatement (must match the plan's behavior statement).

<...>

---

## Engine + engine-specific skill

- Engine confirmed: `<name + version>`
- Engine-specific skill used: `<name>`
- Fallback applied: `<none | native framework | application-level | pseudo-code only>`
- Notes: `<one line if any non-trivial translation, else "none">`

---

## Files touched

- `<path>` — `<one-line description of change>`
- `<path>` — `<one-line description of change>`

---

## Test run output

```
<verbatim or summarized output, last line is the result line>
<e.g., "tests: 1 failed, 0 passed (RED expected)">
<or:   "tests: 12 passed, 0 failed (GREEN)">
<or:   "tests: 12 passed, 0 failed (REFACTOR — improvements applied)">
```

---

## Decisions made

- `<short bullet>`
- `<short bullet>`

---

## Anti-pattern flags

- `<anti-pattern name (section)>` — `<flagged-and-stopped | flagged-and-proceeded with override from orchestrator>`
- `<...>` — `<...>`

(or: `none`)

---

## Deferred per YAGNI

- `<related change intentionally NOT done — for a future cycle>`
- `<...>`

(or: `none`)

---

## Open questions for the orchestrator

- `<question, or "none">`

---

## Hand-off to next consumer

> What does the next sub-agent / orchestrator need to know to proceed?

- RED → GREEN: failing test path = `<...>`; failure mode = `<...>`.
- GREEN → REFACTOR: implementation paths = `<list>`; suite green at SHA / state `<...>`.
- REFACTOR → next RED (or "feature done"): `<changes summary | "no refactor — proceed">`.

---

## Sign-off

Report author: `<sub-agent role>` — `<ISO timestamp>`
