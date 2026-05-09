#!/usr/bin/env bash
# tdd-skill-forced-eval.sh
# ----------------------------------------------------------------------------
# UserPromptSubmit hook: forces Claude (or any sub-agent) to explicitly
# evaluate and activate the skills required by the TDD database workflow
# BEFORE proceeding to implementation.
#
# Inspired by:
#   - Scott Spence (https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably)
#     "forced eval" raises skill activation from ~20% to ~84%
#   - Alexander Opalic (https://alexop.dev/posts/custom-tdd-workflow-claude-code-vue/)
#     subagent isolation + UserPromptSubmit hook injection
#
# Why this version, beyond the generic forced-eval:
#   The TDD database workflow has a *hierarchical* skill dependency:
#     1. tdd-database-development      (methodology + roles)
#     2. <engine>-tdd-testing          (e.g. pgtap-tdd-testing for PostgreSQL)
#   Naming these explicitly turns the generic forced-eval into a
#   workflow-specific deterministic gate. Outside the TDD context the hook
#   degrades gracefully into a generic "evaluate available skills" prompt.
#
# Idempotency:
#   - The hook only WRITES TO STDOUT. No file mutation. No global state.
#   - Safe to run any number of times in either Linux or macOS.
#
# Compatibility:
#   - POSIX sh / bash / zsh — uses only portable constructs.
#   - No GNU-only flags (no `readlink -f`, no `sed -i ''` differences).
# ----------------------------------------------------------------------------

set -eu

# Drain stdin so Claude Code's pipe does not block the hook on either OS.
# (Some Claude Code versions feed an empty stdin; some feed a JSON event.)
if [ ! -t 0 ]; then
  cat >/dev/null 2>&1 || true
fi

# Heredoc to stdout — Claude Code injects this verbatim into the prompt
# context before sending it to the model. Keep terse: long preambles get
# skipped; aggressive imperative wording ("MUST", "WORTHLESS") raises
# follow-through (Spence, 200+ prompt study).
cat <<'EOF'
INSTRUCTION: MANDATORY SKILL ACTIVATION SEQUENCE — TDD DATABASE WORKFLOW

You are about to act on a database TDD task. Before any other action, complete
these three steps in order. Skipping a step means you skipped TDD.

Step 1 — EVALUATE (write this in your response, one line per skill):
  For each skill in <available_skills>, state:
    [skill-name] — YES / NO — [one-line reason]

  Pay special attention to these workflow-critical skills. If any is present
  in <available_skills> and the prompt involves database TDD, the answer is
  YES — no exceptions:
    - tdd-database-development      (methodology + RED/GREEN/REFACTOR roles)
    - pgtap-tdd-testing             (engine-specific, PostgreSQL)
    - utplsql-tdd-testing           (engine-specific, Oracle)
    - tsqlt-tdd-testing             (engine-specific, SQL Server)
    - mytap-tdd-testing             (engine-specific, MySQL / MariaDB)
    - <other>-tdd-testing           (any other engine-specific TDD skill)

Step 2 — ACTIVATE (do this immediately after Step 1, before anything else):
  For EACH skill marked YES in Step 1, call the Skill() tool NOW. Do not
  describe the skill. Do not summarize it. Call Skill(name) and let the
  skill load.

  Hierarchical rule for the TDD database workflow:
    a) Activate tdd-database-development FIRST.
    b) THEN activate the engine-specific TDD skill matching the database
       engine in scope (PostgreSQL → pgtap-tdd-testing, Oracle → utplsql-
       tdd-testing, SQL Server → tsqlt-tdd-testing, MySQL/MariaDB → mytap-
       tdd-testing, etc.).
    c) If no engine-specific skill exists in <available_skills>, state so
       explicitly and follow the fallback ladder defined in
       tdd-database-development/references/engine-skill-discovery.md.

Step 3 — IMPLEMENT:
  Only after Step 2 is complete, proceed with the actual task (RED test
  writing, GREEN minimum implementation, REFACTOR evaluation).

CRITICAL:
  - You MUST call the Skill() tool in Step 2. Step 1 alone is WORTHLESS
    unless Step 2 follows.
  - If Step 1 produces "No skills needed", state that explicitly and
    proceed — the hook does not force activation when nothing matches.
  - Do NOT skip to implementation. Do NOT paraphrase the skill content
    instead of loading it. Load it.
EOF

# Always exit 0 — a failing hook would block the prompt. Idempotent and safe.
exit 0
